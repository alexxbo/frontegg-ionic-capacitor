import FronteggSwift
import Foundation
import Combine
import Capacitor

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(FronteggNativePlugin)
public class FronteggNativePlugin: CAPPlugin {
    public let fronteggApp = FronteggApp.shared
    var cancellables = Set<AnyCancellable>()

    private var workItem: DispatchWorkItem?
    private let delay: TimeInterval = 0.05  // 200ms delay

    func debounce(_ action: @escaping () -> Void) {
        workItem?.cancel()
        let newWorkItem = DispatchWorkItem(block: action)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
        workItem = newWorkItem
    }

    override public func load() {

        let auth = fronteggApp.auth
        var anyChange: AnyPublisher<Void, Never> {
            return Publishers.Merge8 (
                auth.$accessToken.map { _ in },
                auth.$refreshToken.map {_ in },
                auth.$user.map {_ in },
                auth.$isAuthenticated.map {_ in },
                auth.$isLoading.map {_ in },
                auth.$initializing.map {_ in },
                auth.$showLoader.map {_ in },
                auth.$selectedRegion.map{_ in}
            )
            .eraseToAnyPublisher()
        }

        anyChange.sink(receiveValue: { () in
            self.debounce() {
                self.sendEvent()
            }
        }).store(in: &cancellables)

        self.sendEvent()
    }



    func sendEvent() {
        let auth = fronteggApp.auth

        var jsonUser: [String: Any]? = nil
        if let userData = try? JSONEncoder().encode(auth.user) {
            jsonUser = try? JSONSerialization.jsonObject(with: userData, options: .allowFragments) as? [String: Any]
        }

        let body: [String: Any?] = [
            "accessToken": auth.accessToken,
            "refreshToken": auth.refreshToken,
            "user": jsonUser,
            "isAuthenticated": auth.isAuthenticated,
            "isLoading": auth.isLoading,
            "initializing": auth.initializing,
            "showLoader": auth.showLoader,
            "selectedRegion": regionToJson(auth.selectedRegion)
        ]

        self.notifyListeners("onFronteggAuthEvent", data: body as [String : Any])
    }


    func regionToJson(_ region: RegionConfig?) -> [String:String]? {

        if let reg = region {
            return [
                "baseUrl": reg.baseUrl,
                "clientId": reg.clientId,
                "key": reg.key
            ]
        }else {
            return nil
        }
    }
    func regionsToJson(_ regions: [RegionConfig]) -> [[String:String]] {

        var regionData: [[String:String]] = []
        regions.forEach { reg in
            if let region = regionToJson(reg) {
                regionData.append(region)
            }
        }

        return regionData
    }

    @objc func getConstants(_ call: CAPPluginCall) {
        call.resolve([
            "baseUrl": fronteggApp.baseUrl,
            "clientId": fronteggApp.clientId,
            "bundleId": Bundle.main.bundleIdentifier!,
            "isRegional": fronteggApp.auth.isRegional,
            "regionData": regionsToJson(fronteggApp.auth.regionData)
        ])
    }

    @objc func login(_ call: CAPPluginCall) {
        DispatchQueue.main.sync {
            fronteggApp.auth.login()
        }
        call.resolve()
    }

    @objc func logout(_ call: CAPPluginCall) {
        DispatchQueue.main.sync {
            fronteggApp.auth.logout()
        }
        call.resolve()
    }

    @objc func switchTenant(_ call: CAPPluginCall) {
        guard let tenantId = call.options["tenantId"] as? String else {
            call.reject("No tenantId provided")
            return
        }

        fronteggApp.auth.switchTenant(tenantId: tenantId) { _ in
            call.resolve()
        }
    }

    @objc func initWithRegion(_ call: CAPPluginCall) {
        guard let regionKey = call.options["regionKey"] as? String else {
            call.reject("No regionKey provided")
            return
        }

        fronteggApp.initWithRegion(regionKey: regionKey)
    }

    @objc func refreshToken(_ call: CAPPluginCall) {

        DispatchQueue.global(qos: .background).async {
            Task {
                await self.fronteggApp.auth.refreshTokenIfNeeded()
                call.resolve()
            }
        }
    }

    @objc func getAuthState(_ call: CAPPluginCall) {
        let auth = fronteggApp.auth
        var jsonUser: [String: Any]? = nil
        if let userData = try? JSONEncoder().encode(auth.user) {
            jsonUser = try? JSONSerialization.jsonObject(with: userData, options: .allowFragments) as? [String: Any]
        }

        let body: [String: Any?] = [
            "accessToken": auth.accessToken,
            "refreshToken": auth.refreshToken,
            "user": jsonUser,
            "isAuthenticated": auth.isAuthenticated,
            "isLoading": auth.isLoading,
            "initializing": auth.initializing,
            "showLoader": auth.showLoader,
            "selectedRegion": regionToJson(auth.selectedRegion)
        ]
        call.resolve(body as [String: Any] )
    }

}
