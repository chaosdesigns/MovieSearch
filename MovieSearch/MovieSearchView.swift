//
//  MovieSearchView.swift
//  MovieSearch
//
//  Created by Jeff Ferguson on 2025-02-28.
//

import SwiftUI

struct MovieSearchView: View {
	@StateObject private var model = MovieModel.shared // we just need one
	@State private var showAbout = false

	var body: some View {

		NavigationView {
			VStack {
				if model.isLoading {
					Spacer()
					ProgressView()
						.scaleEffect(3)
					Spacer()
				} else {
					List {
						ForEach(model.movies) { movie in
							MovieListCell(movie: movie)
								.onAppear() {
									// when the cell appears, fetch more movies from internet, if needed
									model.fetchMoreResultsIfNeeded(currentMovie: movie)
								}
						}
					}
					.listStyle(PlainListStyle())
					.listItemTint(Color.clear)

					if model.movies.count > 0 {
						ListFooterView(total: model.totalCount)
					} else {
						Text(model.messageText)
							.font(.body)
							.fontWeight(.light)
							.foregroundColor(model.messageColor)
							.multilineTextAlignment(.center)
							.padding(30)
					}
				}
			}
			.searchable(text: $model.searchText, prompt: "Find movie...")	// use built in search bar
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
							.foregroundColor(.yellow)
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

	var body: some View {
		Text("\(total) Movies Found")
			.font(.body)
			.foregroundColor(.secondary)
			.fontWeight(.light)
	}
}

fileprivate struct AboutView: View {
	@Environment(\.presentationMode) var presentationMode

	var body: some View {
		VStack {
			Text("Written by Jeff Ferguson")
				.font(.body)
				.padding()
				.padding(.bottom, 20)

			Button("Close") {
				presentationMode.wrappedValue.dismiss()
			}
			.padding()
		}
	}
}

#Preview {
    MovieSearchView()
}
