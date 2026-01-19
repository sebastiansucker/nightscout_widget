//
//  SettingsView.swift
//  NightscoutWidget
//
//  Created on 19.01.2026.
//

import SwiftUI
import WidgetKit

struct SettingsView: View {
    @AppStorage("nightscoutUrl", store: UserDefaults(suiteName: "group.com.nightscout.widget"))
    private var nightscoutUrl = ""
    
    @AppStorage("accessToken", store: UserDefaults(suiteName: "group.com.nightscout.widget"))
    private var accessToken = ""
    
    @AppStorage("bgUnits", store: UserDefaults(suiteName: "group.com.nightscout.widget"))
    private var bgUnits = "mgdl"
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Form {
            Section(header: Text("Nightscout-Konfiguration")) {
                TextField("Nightscout URL", text: $nightscoutUrl)
                    .textFieldStyle(.roundedBorder)
                    .help("Deine Nightscout-Server URL (z.B. https://deine-seite.herokuapp.com)")
                
                TextField("Access Token (optional)", text: $accessToken)
                    .textFieldStyle(.roundedBorder)
                    .help("Access Token falls dein Server geschützt ist")
            }
            
            Section(header: Text("Anzeigeeinstellungen")) {
                Picker("BG-Einheiten:", selection: $bgUnits) {
                    Text("mg/dL").tag("mgdl")
                    Text("mmol/L").tag("mmol")
                }
                .pickerStyle(.segmented)
            }
            
            Section {
                HStack {
                    Spacer()
                    Button("Verbindung testen") {
                        testConnection()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Schwellenwerte laden") {
                        loadThresholds()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Widget neu laden") {
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                }
                
                Text("Nach dem Ändern der Einstellungen bitte 'Widget neu laden' drücken oder das Widget vom Desktop entfernen und neu hinzufügen.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Lade die Schwellenwerte aus deiner Nightscout-Konfiguration, um die BG-Bereiche (Grün/Gelb/Rot) automatisch anzupassen.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 550, height: 400)
        .alert("Test", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func testConnection() {
        guard !nightscoutUrl.isEmpty else {
            alertMessage = "Bitte gib eine Nightscout URL ein."
            showAlert = true
            return
        }
        
        var urlString = nightscoutUrl
        if !accessToken.isEmpty {
            urlString += "/api/v1/entries.json?count=1&token=" + accessToken
        } else {
            urlString += "/api/v1/entries.json?count=1"
        }
        
        guard let url = URL(string: urlString) else {
            alertMessage = "Ungültige URL"
            showAlert = true
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    alertMessage = "Fehler: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    alertMessage = "Keine gültige Antwort vom Server"
                    showAlert = true
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    alertMessage = "✓ Verbindung erfolgreich!"
                } else {
                    alertMessage = "Fehler: HTTP \(httpResponse.statusCode)"
                }
                showAlert = true
            }
        }.resume()
    }
    
    private func loadThresholds() {
        guard !nightscoutUrl.isEmpty else {
            alertMessage = "Bitte gib zuerst eine Nightscout URL ein."
            showAlert = true
            return
        }
        
        Task {
            do {
                let thresholds = try await NightscoutService.shared.fetchThresholds()
                
                await MainActor.run {
                    alertMessage = """
                    ✓ Schwellenwerte erfolgreich geladen!
                    
                    mg/dL: Niedrig < \(Int(thresholds.bgLowMgdl)), Hoch > \(Int(thresholds.bgHighMgdl))
                    mmol/L: Niedrig < \(String(format: "%.1f", thresholds.bgLowMmol)), Hoch > \(String(format: "%.1f", thresholds.bgHighMmol))
                    """
                    showAlert = true
                    
                    // Widget neu laden, damit die neuen Schwellenwerte verwendet werden
                    WidgetCenter.shared.reloadAllTimelines()
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Fehler beim Laden der Schwellenwerte: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
