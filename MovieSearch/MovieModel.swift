//
//  MovieModel.swift
//  MovieSearch
//
//  Created by Jeff Ferguson on 2025-02-28.
//


import Foundation
import SwiftUI

@MainActor class MovieModel: ObservableObject {
	static var shared = MovieModel()

	@Published var movies = [MovieRec]()
	@Published var totalCount = 0
	@Published var errorMessage: String?
	@Published var searchText = ""

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

	// called when list cell becomes visible, so next page of results can be loaded
	func handleListCellBecomesVisible(currentMovie: MovieRec) async {
		do {
			errorMessage = nil
			try await fetchMoreResultsIfNeededUsingOmdb(currentMovie: currentMovie)
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	// called when the searchText changes to reload the list with movies that match the user's search parameter
	func handleSearchTextChanged() {
		Task {
			do {
				movies = [MovieRec]()
				totalCount = 0
				currentPage = 0
				canLoadMorePages = true
				errorMessage = nil
				try await fetchMoreResultsUsingOmdb()
			} catch {
				errorMessage = error.localizedDescription
			}
		}
	}

//MARK: - Private
	private var currentPage = 0
	private var canLoadMorePages = true
	private var omdb = OMDbModel.shared

	private func fetchMoreResultsIfNeededUsingOmdb(currentMovie movie:  MovieRec) async throws {
		let rowsBeforeLoading = -5	// ...(5 rows before needed)
		let thresholdIndex = movies.index(movies.endIndex, offsetBy: rowsBeforeLoading)
		if movies.firstIndex(where: { $0.id == movie.id }) == thresholdIndex {
			try await fetchMoreResultsUsingOmdb()
		}
	}

	private func fetchMoreResultsUsingOmdb() async throws {
		guard canLoadMorePages else { return }
		try await loadAPageOfResultsUsingOmdb()
	}

	private func loadAPageOfResultsUsingOmdb() async throws {
		guard !searchText.isEmpty else { return }

		do {
			let results: (movies: [MovieEntry], total: Int) = try await omdb.loadAPageOfMovies(searchText: searchText, pageNum: currentPage)
			processFetchedMovies(moviesIn: results.movies, total: results.total)
		} catch {
			throw error.localizedDescription
		}
	}

	private func processFetchedMovies(moviesIn: [MovieEntry], total: Int) {
		for movie in moviesIn {
			let movieInfo = MovieRec(id: UUID(), movie: movie, posterImage: nil)
			let nextIndex = self.movies.count
			self.movies.append(movieInfo)

			if movies[nextIndex].posterImage == nil,
			    let posterUrlString = movieInfo.movie.Poster,
				!posterUrlString.isEmpty,
				posterUrlString != "N/A",
				let url = URL(string: posterUrlString) {
					Task {
						do {
							let poster: (index: Int, image: UIImage?) = try await self.omdb.loadPosterForMovie(forIndex: nextIndex, fromUrl: url)
							guard poster.index < movies.count else {
								return
							}
							movies[poster.index].posterImage = poster.image
						} catch {
							// no point exposing this error to the user
							// just print to console so dev can see it
							print("Error loading poster for movie \(nextIndex): \(error)")
						}
					}
			}
		}
		currentPage += 1
		totalCount = total
		canLoadMorePages = movies.count < totalCount
	}
}
