//
//  MovieModel.swift
//  MovieSearch
//
//  Created by Jeff Ferguson on 2025-02-28.
//
//  Uses OMDb API  http://www.omdbapi.com/
//  Free API key: http://www.omdbapi.com/apik
//  My key: 54af0851
//  OMDb API: http://www.omdbapi.com/?i=tt3896198&apikey=54af0851


import Foundation
import SwiftUI

class MovieModel: ObservableObject {
	@Published var movies = [MovieRec]()
	@Published var totalCount = 0
	@Published var errorMessage: String?
	@Published var isLoading = false
	@Published var searchText = "" {
		didSet {
			// as the user changes the text, we re-trigger the search
			changeFetchParameters()
		}
	}
	private let apiKey = "54af0851"
	private let basePath = "https://www.omdbapi.com/"
	private var pendingFetch = false;
	private var currentPage = 0
	private var canLoadMorePages = true

	static var shared = MovieModel()

	var messageText: String {
		if let errorMessage = errorMessage {
			return errorMessage
		} else if searchText.isEmpty {
			return "Enter some text to search for a movie."
		} else {
			return "There are no movies matching your search."
		}
	}

	var messageColor: Color {
		if errorMessage != nil {
			return .red
		} else {
			return .secondary
		}
	}

	// called when the searchText changes to reload the list with
	// movies that match the user's search parameter
	func changeFetchParameters() {
		guard !isLoading else {
			// remember that we want to fetch (as soon as the current one is done)
			pendingFetch = true
			return
		}
		pendingFetch = false
		movies = [MovieRec]()
		totalCount = 0
		currentPage = 0
		canLoadMorePages = true
		errorMessage = nil
		fetchMoreResults()
	}

	// called when a movie list cell is displayed
	// this determines if more results need to be loaded (soon)
	func fetchMoreResultsIfNeeded(currentMovie movie:  MovieRec) {

		let rowsBeforeLoading = -5	// ...(5 rows before needed)
		let thresholdIndex = movies.index(movies.endIndex, offsetBy: rowsBeforeLoading)
		if movies.firstIndex(where: { $0.id == movie.id }) == thresholdIndex {
			fetchMoreResults()
		}
	}

	// begins and continues loading pages of results
	private func fetchMoreResults() {
		guard !isLoading && canLoadMorePages else {
			return
		}

		loadAPageOfResults(pageNum: currentPage)
	}

	// called to load a page of search results and process them into the model
	func loadAPageOfResults(pageNum: Int) {
		guard !isLoading, !searchText.isEmpty else {
			return
		}
		errorMessage = nil

		let urlString = "\(basePath)?s=\(searchText)&page=\(currentPage+1)&type=movie&apikey=\(apiKey)"
		//print("Loading page using url: [\(urlString)]") // handy debug statement
		guard let url = URL(string: urlString) else {
			print("Invalid url: [\(urlString)]")
			errorMessage = "Invalid url: [\(urlString)]"
			return
		}

		isLoading = true

		URLSession.shared.dataTask(with: url) { data, response, error in
			DispatchQueue.main.async {
				self.isLoading = false
			}
			if let error = error {
				DispatchQueue.main.async {
					self.errorMessage = "Error: \(error.localizedDescription)"
				}
				print("Error: \(error.localizedDescription)")
				return
			}

			guard let data = data else {
				DispatchQueue.main.async {
					self.errorMessage = "No data received."
				}
				print("Error: No data received.")
				return
			}

			do {
				let decoder = JSONDecoder()
				let results = try decoder.decode(SearchResult.self, from: data)

				guard let validResponse = results.Response else {
					print("Error: Invalid Response.")
					return
				}
				if validResponse == "False" {
					let errorMsg = results.Error ?? "No error message provided."
					DispatchQueue.main.async {
						self.errorMessage = errorMsg
					}
					print(results.Error ?? "No error message provided.")
					return
				}
				DispatchQueue.main.async() {
					self.processFetchedResults(results: results)
				}
			} catch {
				DispatchQueue.main.async {
					self.errorMessage = "Error parsing JSON: \(error.localizedDescription)"
				}
				print("Error parsing JSON: \(error.localizedDescription)")
				return
			}
		}.resume()
	}

	func processFetchedResults(results: SearchResult) {
		print("processFetchedResults")

		guard let movies = results.Search else {
			print("Error No search results.")
			return
		}
		for movie in movies {
			let movieInfo = MovieRec(id: UUID(), movie: movie, posterImage: nil)
			let nextIndex = self.movies.count
			self.movies.append(movieInfo)
			self.requestPosterForMovieIndex(nextIndex)
		}
		currentPage += 1
		totalCount = Int(results.totalResults ?? "0") ?? 0
		canLoadMorePages = movies.count < totalCount
	}

	// called after a movie record is created... to load its poster
	func requestPosterForMovieIndex(_ index: Int) {
		guard index < movies.count,
			  movies[index].posterImage == nil,
			  let posterUrlString = movies[index].movie.Poster,
			  !posterUrlString.isEmpty,
			  posterUrlString != "N/A",
			  let url = URL(string: posterUrlString) else {
			return
		}

		getData(from: url) { optData, response, error in
			guard let imageData = optData else {
				return
			}

			DispatchQueue.main.async() {
				guard index < self.movies.count else {
					return
				}
				let uiImage: UIImage? = UIImage(data: imageData)
				self.movies[index].posterImage = uiImage
			}
		}
	}

	private func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
		//print("Poster URL: \(url)")
		URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
	}
}

public struct MovieEntry: Equatable, Decodable {
	public let Title: String?		//display
	public let Year: String?		//display
	public let `Type`: String?
	public let Poster: String?		//display
}

public struct MovieRec: Identifiable {
	public var id: UUID
	public var movie: MovieEntry
	public var posterImage: UIImage? = nil
}

public struct SearchResult: Equatable, Decodable {
	public let Search: [MovieEntry]?
	public let Response: String?
	public let totalResults: String?
	public let Error: String?
}

public struct Rating: Equatable, Decodable {
	public let Source: String?
	public let Value: String?
}

public struct MovieDetail: Equatable, Decodable {
	public let Title: String?		//display
	public let Year: String?		//display
	public let Released: String?
	public let Poster: String?		//display
	public let Rated: String?
	public let Runtime: String?
	public let Genre: String?
	public let Director: String?
	public let Writer: String?
	public let Actors: String?
	public let Plot: String?
	public let Language: String?
	public let Country: String?
	public let Awards: String?
	public let Ratings: [Rating]?
	public let Metascore: String?
	public let imdbRating: String?
	public let imdbVotes: String?
	public let imdbID: String?
	public let `Type`: String?
	public let DVD: String?
	public let BoxOffice: String?
	public let Production: String?
	public let Website: String?
	public let Response: String?
	public let Error: String?
}
