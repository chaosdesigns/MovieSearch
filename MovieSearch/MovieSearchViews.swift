//
//  MovieSearchViews.swift
//  MovieSearch
//
//  Created by Jeff Ferguson on 2025-02-28.
//

import SwiftUI

struct MovieSearchView: View {
	@StateObject private var model = MovieModel.shared // singleton
	@State private var showAbout = false

	var body: some View {
		NavigationView {
			VStack {
				List {
					ForEach(model.movies) { movie in
						MovieListCell(movie: movie)
							.onAppear() {
								// when the cell appears, fetch more movies, if needed
								model.fetchMoreResultsIfNeeded(currentMovie: movie)
							}
					}
				}
				.listStyle(PlainListStyle())
				.listItemTint(Color.clear)

				if model.movies.count > 0 {
					ListFooterView(total: model.totalCount, loaded: model.movies.count)
				} else {
					Text(model.messageText)
						.font(.body)
						.fontWeight(.light)
						.foregroundColor(model.messageColor)
						.multilineTextAlignment(.center)
						.padding(30)
				}
			}
			.searchable(text: $model.searchText, prompt: "Find movie...")
			.navigationTitle("Movie Search")
			.toolbar {
				ToolbarItem(placement: .navigationBarTrailing) {
					Button("About") {
						showAbout.toggle()
					}
				}
			}
		}
		.sheet(isPresented: $showAbout) {
			AboutView()
		}
	}
}

fileprivate struct MovieListCell: View {
	var movie: MovieRec
	@State private var like = false

	var body: some View {
		HStack {
			MoviePosterView(image: movie.posterImage)

			VStack(alignment: .leading) {
				Text("\(movie.movie.Title ?? "")")
					.font(.body)
					.fontWeight(.bold)

				Text("Year: \(movie.movie.Year ?? "")")
					.font(.caption)
					.foregroundColor(.secondary)

				HStack {
					Button(action: {
						like.toggle()
						//print("button tapped id: \(movie.id)")
					}) {
						Image(systemName: "star.fill")
							.foregroundColor(like ? .yellow : .blue)
					}
					.buttonStyle(.borderless) // prevents full-row tap interference

					if like {
						Text("I like this movie!")
							.font(.caption)
							.foregroundColor(.secondary)
							.padding(.horizontal)
					}
					Spacer()
				}
			}.padding(.horizontal)
			Spacer()
		}
	}
}

fileprivate struct MoviePosterView : View {
	var image: UIImage?

	var body: some View {
		Image(uiImage: image ?? UIImage(named: "no-poster")!)
			.resizable()
			.aspectRatio(contentMode: .fit)
			.frame(width: 120, height: 200)
	}
}

fileprivate struct ListFooterView: View {
	var total: Int
	var loaded: Int

	var body: some View {
		Text("\(total) Movies Found, \(loaded) Loaded")
			.font(.body)
			.foregroundColor(.secondary)
			.fontWeight(.light)
	}
}

fileprivate struct AboutView: View {
	@Environment(\.presentationMode) var presentationMode

	var body: some View {
		ZStack(alignment: .topTrailing) {
			Color.white.ignoresSafeArea()

			VStack {
				Text("Movie Search")
					.font(.largeTitle)
					.bold()
					.padding(.bottom, 15)

				Image(uiImage: UIImage(named: "MovieSearch")!)
					.resizable()
					.aspectRatio(contentMode: .fit)
					.frame(width: 300, height: 300)
					.padding(.bottom, 30)

				Text("Written by Jeff Ferguson")
					.font(.body)

				Text("for Ensemble Systems, Mar 2, 2025")
					.font(.caption)
					.foregroundColor(.secondary)
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.background(Color.clear)

			Button(action: {
				presentationMode.wrappedValue.dismiss()
			}) {
				Image(systemName: "xmark")
					.font(.title2)
					.padding(12)
					.background(Color.gray.opacity(0.1))
					.clipShape(Circle())
					.foregroundColor(.blue)
			}
			.padding(.top, 10)
			.padding(.trailing, 15)
		}
	}
}

//MARK: - Previews

#Preview("Search") {
	MovieSearchView()
}

#Preview("List Cell") {
	MovieListCell(movie: MovieRec(
		id: UUID(),
		movie: MovieEntry(
			Title: "Star Wars: Empire Strikes Back",
			Year: "1983",
			Type: nil,
			Poster: nil),
		posterImage: UIImage(named: "no-poster")!)
	)
}

#Preview("Poster") {
	MoviePosterView()
}

#Preview("Footer") {
	ListFooterView(total: 1234, loaded: 234)
}
#Preview("About") {
	AboutView()
}
