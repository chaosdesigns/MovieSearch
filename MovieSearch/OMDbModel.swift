//
//  OMDbModel.swift
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

//MARK: - OMDbModel
class OMDbModel: ObservableObject {
	static var shared = OMDbModel()

	private let apiKey = "54af0851"
	private let basePath = "https://www.omdbapi.com/"

	// called to load a page of search results and process them into the model
	func loadAPageOfMovies(searchText: String, pageNum: Int) async throws -> (movies: [MovieEntry], total: Int) {
		guard !searchText.isEmpty else {
			throw "Search Text is empty."
		}

		let urlString = "\(basePath)?s=\(searchText)&page=\(pageNum+1)&type=movie&apikey=\(apiKey)"
		//print("Loading page using url: [\(urlString)]") // handy debug statement
		guard let url = URL(string: urlString) else {
			throw "Invalid url: [\(urlString)]"
		}

		let (data, response) = try await URLSession.shared.data(from: url)
		
		guard (response as? HTTPURLResponse)?.statusCode == 200 else {
			throw "The server responded with an error."
		}
		guard let results = try? JSONDecoder().decode(SearchResult.self, from: data) else {
			throw "The server response was not recognized. (Error parsing JSON)"
		}
		guard let validResponse = results.Response else {
			throw "Error: Invalid Response."
		}
		guard validResponse == "True" else {
			throw (results.Error ?? "No error message provided.")
		}
		guard results.Search?.count ?? 0 > 0 else {
			throw "No Search Results."
		}

		return (
			movies: results.Search ?? [],
			total: Int(results.totalResults ?? "0") ?? 0
		)
	}

	func loadPosterForMovie(forIndex: Int, fromUrl: URL) async throws -> (index: Int, image: UIImage?) {
		let (data, response) = try await URLSession.shared.data(from: fromUrl)

		let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
		guard statusCode == 200 else {
			let statusCodeMsg = statusCode == 0 ? "" : "(\(statusCode)) "
			throw "The server responded with an error code \(statusCodeMsg)while loading from poster url \(fromUrl)."
		}
		return (
			index: forIndex,
			image: UIImage(data: data)
		)
	}
}

//MARK: - Structures

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


extension String: @retroactive Error {}
extension String: @retroactive LocalizedError {
	public var errorDescription: String? {
		return self
	}
}
