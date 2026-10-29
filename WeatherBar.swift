import AppKit
import CoreLocation

private struct Forecast: Decodable {
    struct Current: Decodable {
        let temperature_2m: Double
        let weather_code: Int
        let is_day: Int
    }
    let current: Current
}

final class AppDelegate: NSObject, NSApplicationDelegate, CLLocationManagerDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let locationManager = CLLocationManager()
    private var location: CLLocation?
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem.button?.title = "--°"
        statusItem.button?.imagePosition = .imageLeading

        let menu = NSMenu()
        let quit = NSMenuItem(title: "Quit WeatherBar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp
        menu.addItem(quit)
        statusItem.menu = menu

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.distanceFilter = 1000
        locationManager.requestWhenInUseAuthorization()
        // The initial authorization callback fires when the manager is created, before the delegate is set
        locationManagerDidChangeAuthorization(locationManager)

        timer = Timer.scheduledTimer(withTimeInterval: 15 * 60, repeats: true) { [weak self] _ in self?.refresh() }
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(refresh), name: NSWorkspace.didWakeNotification, object: nil)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorized: manager.startUpdatingLocation()
        case .denied, .restricted: statusItem.button?.title = "No location"
        default: break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        location = latest
        refresh()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        NSLog("WeatherBar location error: \(error)")
    }

    @objc private func refresh() {
        guard let coordinate = location?.coordinate else {
            locationManager.startUpdatingLocation()
            return
        }
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code,is_day"),
            URLQueryItem(name: "temperature_unit", value: "celsius")
        ]
        URLSession.shared.dataTask(with: components.url!) { [weak self] data, _, error in
            guard let data, let forecast = try? JSONDecoder().decode(Forecast.self, from: data) else {
                NSLog("WeatherBar fetch failed: \(String(describing: error))")
                DispatchQueue.main.asyncAfter(deadline: .now() + 60) { self?.refresh() }
                return
            }
            DispatchQueue.main.async { self?.show(forecast.current) }
        }.resume()
    }

    private func show(_ current: Forecast.Current) {
        let isDay = current.is_day == 1
        let image = NSImage(systemSymbolName: Self.symbolName(code: current.weather_code, isDay: isDay), accessibilityDescription: nil)
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.title = "\(Int(current.temperature_2m.rounded()))°"
    }

    // WMO weather interpretation codes, see https://open-meteo.com/en/docs
    private static func symbolName(code: Int, isDay: Bool) -> String {
        switch code {
        case 0: return isDay ? "sun.max.fill" : "moon.stars.fill"
        case 1, 2: return isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51...57: return "cloud.drizzle.fill"
        case 65, 82: return "cloud.heavyrain.fill"
        case 61...67, 80...82: return "cloud.rain.fill"
        case 71...77, 85, 86: return "cloud.snow.fill"
        case 95...99: return "cloud.bolt.rain.fill"
        default: return "cloud.fill"
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
