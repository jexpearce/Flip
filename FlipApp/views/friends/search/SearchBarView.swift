import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

struct SearchBarView: View {
    @Binding var searchText: String
    let orangeAccent: Color
    let orangeGlow: Color
    var onSearchTextChanged: (String) -> Void

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(orangeAccent)
                .font(.system(size: 20)).shadow(color: orangeGlow, radius: 4).padding(.leading, 6)

            TextField("Search by username", text: $searchText).font(.system(size: 16))
                .foregroundColor(.white).accentColor(orangeAccent).padding(.vertical, 12)
                .onChange(of: searchText) { onSearchTextChanged(searchText) }
                .autocapitalization(.none).disableAutocorrection(true)
        }
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12).stroke(Theme.silveryGradient4, lineWidth: 1)
                )
        )
        .padding(.horizontal).padding(.top, 16).padding(.bottom, 12)
    }
}
