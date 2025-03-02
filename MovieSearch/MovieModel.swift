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

	// some working variables as we page the load
	@Published var isLoading = false {
		didSet {
			if isLoading == false && pendingFetch == true {
				// trigger the pending fetch
				changeFetchParameters()
			}
		}
	}
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

	init() {
		fetchMoreResults()
	}

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
		pendingFetch = false	// we are fetching, so clear pending flag
		movies = [MovieRec]()
		totalCount = 0
		currentPage = 0
		canLoadMorePages = true
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
		guard !searchText.isEmpty else {
			return
		}
		errorMessage = nil

		var urlString = "\(basePath)?s=\(searchText)&page=\(currentPage+1)&type=movie&apikey=\(apiKey)"
		// cleanup the URL so we dont crash
		urlString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
		urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
		print("Loading page using url: [\(urlString)]") // handy debug statement

		guard let url = URL(string: urlString) else {
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
				return
			}

			guard let data = data else {
				DispatchQueue.main.async {
					self.errorMessage = "No data received."
				}
				return
			}

			do {
				let decoder = JSONDecoder()
				let results = try decoder.decode(SearchResult.self, from: data)
				guard let movies = results.Search else {
					return
				}

				DispatchQueue.main.async() {
					for movie in movies {
						let movieInfo = MovieRec(id: UUID(), movie: movie, posterImage: nil)
						let nextIndex = self.movies.count
						print("Next Index: \(nextIndex)")
						self.movies.append(movieInfo)
						self.requestPosterForMovieIndex(nextIndex)
					}
					self.currentPage += 1
					self.totalCount = Int(results.totalResults ?? "0") ?? 0
					self.canLoadMorePages = self.movies.count < self.totalCount
				}
			} catch {
				DispatchQueue.main.async {
					self.errorMessage = "Error parsing JSON: \(error.localizedDescription)"
				}
				return
			}
		}.resume()
	}

	// called after a movie record is created... to load its poster
	func requestPosterForMovieIndex(_ index: Int) {
		guard index < movies.count,
			  movies[index].posterImage == nil,
			  let posterUrlString = movies[index].movie.Poster,
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
