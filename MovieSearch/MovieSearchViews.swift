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
		NavigationStack {
			VStack {
				List {
					ForEach(model.movies) { movie in
						NavigationLink(destination: DetailView(movie: movie)) {
							MovieListCell(movie: movie)
								.task { // when the cell appears, fetch more movies, if needed
									await model.handleListCellBecomesVisible(currentMovie: movie)
								}
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
			.onChange(of: model.searchText) { _, _ in
				model.handleSearchTextChanged()
			}
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

struct DetailView: View {
	@StateObject private var model = MovieDetailsModel.shared
	var movie: MovieRec

	var body: some View {
		VStack(spacing: 20) {
			HStack {
				Text("\(movie.movie.Title ?? "Details")")
					.font(.title2)
					.bold()
				Spacer()
			}
			.padding(.horizontal)

			if model.hasPlotText {
				HStack {
					Image(uiImage: movie.posterImage ?? UIImage(named: "no-poster")!)
						.resizable()
						.aspectRatio(contentMode: .fit)
						.frame(width: 120, height: 150)
					Spacer()
					Text("\(model.plotText)")
						.font(.headline)
				}
				.padding(.horizontal)
			}

			if model.isLoading {
				ProgressView()
			} else {
				if model.errorMessage != nil {
					Text(model.errorMessage!)
						.foregroundColor(.red)
				} else {
					List(model.details, id: \.0) { (title, value) in
						HStack {
							Text(title)
								.font(.headline)
							Spacer()
							Text(value)
								.foregroundColor(.gray)
						}
						.padding(.vertical, 5)
					}
					Spacer()
				}
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
		.task {
			await model.loadDetailsFor(movie: movie)
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
			imdbID: "12345",
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

#Preview("Detail") {
	DetailView(movie: MovieRec(
		id: UUID(),
		movie: MovieEntry(
			Title: "Star Wars: Empire Strikes Back",
			Year: "1983",
			imdbID: "tt12274228",
			Type: nil,
			Poster: nil),
		posterImage: UIImage(named: "no-poster")!)
	)
}
