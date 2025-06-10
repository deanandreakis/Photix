//
//  SettingsView.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import SwiftUI
import StoreKit
import MessageUI

struct SettingsView: View {
    @EnvironmentObject private var storeManager: StoreManager
    @EnvironmentObject private var dependencies: DependencyContainer
    
    @State private var showingMailComposer = false
    @State private var showingPurchaseConfirmation = false
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Tip Jar Section
                    tipJarSection
                    
                    // Support Section
                    supportSection
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingMailComposer) {
                MailComposeView()
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .confirmationDialog(
                selectedProduct?.displayName ?? "",
                isPresented: $showingPurchaseConfirmation
            ) {
                Button("Cancel", role: .cancel) { }
                Button("Buy \(selectedProduct?.displayPrice ?? "")") {
                    purchaseProduct()
                }
            } message: {
                if let product = selectedProduct {
                    Text("\(product.displayName): \(product.description)")
                }
            }
            .overlay {
                if isPurchasing {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                
                                Text("Please wait...")
                                    .foregroundColor(.white)
                                    .font(.headline)
                            }
                        }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image("General")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(spacing: 4) {
                Text("OilPaintPlus")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Oil Paint Effect Photo Editor")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var tipJarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Support Development")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Enjoying Photix? Consider leaving a tip to support continued development!")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if storeManager.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading products...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(storeManager.products, id: \.id) { product in
                        TipButton(
                            product: product,
                            isPurchased: storeManager.isPurchased(product.id)
                        ) {
                            selectedProduct = product
                            showingPurchaseConfirmation = true
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Get Support")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                SupportButton(
                    title: "Email Support",
                    icon: "envelope.fill",
                    color: .green
                ) {
                    if MFMailComposeViewController.canSendMail() {
                        showingMailComposer = true
                    } else {
                        alertTitle = "Mail Not Available"
                        alertMessage = "Please configure Mail app to send emails."
                        showingAlert = true
                    }
                }
                
                SupportButton(
                    title: "Rate App",
                    icon: "star.fill",
                    color: .orange
                ) {
                    rateApp()
                }
                
                SupportButton(
                    title: "Restore Purchases",
                    icon: "arrow.clockwise",
                    color: .green
                ) {
                    Task {
                        await storeManager.restorePurchases()
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private func purchaseProduct() {
        guard let product = selectedProduct else { return }
        
        isPurchasing = true
        
        Task {
            let success = await storeManager.purchase(product)
            
            await MainActor.run {
                isPurchasing = false
                
                if success {
                    alertTitle = "Thank You!"
                    alertMessage = "Your tip is greatly appreciated!"
                    showingAlert = true
                } else if let error = storeManager.error {
                    alertTitle = "Purchase Failed"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
    
    private func rateApp() {
        let reviewURL = "itms-apps://itunes.apple.com/app/id827491007"
        if let url = URL(string: reviewURL) {
            UIApplication.shared.open(url)
        }
    }
}

struct TipButton: View {
    let product: Product
    let isPurchased: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text(product.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isPurchased {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                } else {
                    Text(product.displayPrice)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
        .disabled(isPurchased)
        .opacity(isPurchased ? 0.7 : 1.0)
    }
}

struct SupportButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
    }
}

struct MailComposeView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setSubject("OilPaintPlus Support")
        composer.setToRecipients(["dean@deanware.com"])
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView
        
        init(_ parent: MailComposeView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.dismiss()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(StoreManager.shared)
        .environmentObject(DependencyContainer.shared)
}