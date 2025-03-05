//
//  MovieDetailsModel.swift
//  MovieSearch
//
//  Created by Jeff Ferguson on 2025-03-05.
//

import Foundation
import SwiftUI

@MainActor class MovieDetailsModel: ObservableObject {
	static var shared = MovieDetailsModel()

	@Published var errorMessage: String?
	@Published var isLoading = false
	@Published var details: [(String, String)] = []
	var fetchedDetails: MovieDetail? = nil

	private var omdb = OMDbModel.shared

	var hasPlotText: Bool {
		fetchedDetails?.Plot?.count ?? 0 > 0
	}

	var plotText: String {
		fetchedDetails?.Plot ?? ""
	}

	func updateDetails() -> [(String, String)] {
		return [
			("Year", fetchedDetails?.Year),
			("Released", fetchedDetails?.Released),
			("Rated", fetchedDetails?.Rated),
			("Runtime", fetchedDetails?.Runtime),
			("Genre", fetchedDetails?.Genre),
			("Director", fetchedDetails?.Director),
			("Writer", fetchedDetails?.Writer),
			("Actors", fetchedDetails?.Actors),
			("Language", fetchedDetails?.Language),
			("Country", fetchedDetails?.Country),
			("Awards", fetchedDetails?.Awards),
			("Metascore", fetchedDetails?.Metascore)
		].compactMap { (title, value) in
			value.map {(title, $0)}
		}
	}

	func loadDetailsFor(movie: MovieRec) async {
		guard let movieID = movie.movie.imdbID else {
			return
		}

		do {
			isLoading = true
			errorMessage = nil
			self.fetchedDetails = try await self.omdb.loadMovieDetails(movieID: movieID)
			self.details = self.updateDetails()
			//print("Details: \(details)")
			isLoading = false
		} catch {
			isLoading = false
			errorMessage = error.localizedDescription
		}
	}
}
