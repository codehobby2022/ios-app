import Foundation
import Alamofire

public final class AssetAPI: MixinAPI {
    
    private enum Path {
        
        static let assets = "/assets"
        static func assets(assetId: String) -> String {
            "/assets/" + assetId
        }
        static func fee(assetId: String) -> String {
            "/assets/\(assetId)/fee"
        }
        
        static func snapshots(limit: Int, offset: String? = nil, assetId: String? = nil, opponentId: String? = nil, destination: String? = nil, tag: String? = nil) -> String {
            var path = "/snapshots?limit=\(limit)"
            if let offset = offset {
                path += "&offset=\(offset)"
            }
            if let assetId = assetId {
                path += "&asset=\(assetId)"
            }
            if let opponentId = opponentId {
                path += "&opponent=\(opponentId)"
            }
            if let destination = destination {
                path += "&destination=\(destination)"
                if let tag = tag, !tag.isEmpty {
                    path += "&tag=\(tag)"
                }
            }
            return path
        }
        static func pendingDeposits(assetId: String, destination: String, tag: String) -> String {
            return "/external/transactions?asset=\(assetId)&destination=\(destination)&tag=\(tag)"
        }
        
        static func search(keyword: String) -> String? {
            return "/network/assets/search/\(keyword)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        }
        static let top = "/network/assets/top?kind=NORMAL"
        
        static let chains = "/network/chains"
        static func chain(chainId: String) -> String {
            "/network/chains/" + chainId
        }
    }
    
    public static func assets(completion: @escaping (MixinAPI.Result<[Asset]>) -> Void) {
        request(method: .get, path: Path.assets, completion: completion)
    }
    
    public static func assets() -> MixinAPI.Result<[Asset]> {
        return request(method: .get, path: Path.assets)
    }
    
    public static func asset(assetId: String, completion: @escaping (MixinAPI.Result<Asset>) -> Void) {
        request(method: .get, path: Path.assets(assetId: assetId), completion: completion)
    }
    
    public static func asset(assetId: String) -> MixinAPI.Result<Asset> {
        return request(method: .get, path: Path.assets(assetId: assetId))
    }
    
    public static func assetPrecision(assetID: String) async throws -> AssetPrecisionResponse {
        try await request(method: .get, path: Path.assets(assetId: assetID))
    }
    
    public static func snapshots(limit: Int, offset: String? = nil, assetId: String? = nil, opponentId: String? = nil, destination: String? = nil, tag: String? = nil) -> MixinAPI.Result<[Snapshot]> {
        assert(limit <= 500)
        return request(method: .get, path: Path.snapshots(limit: limit, offset: offset, assetId: assetId, opponentId: opponentId, destination: destination, tag: tag))
    }
    
    public static func snapshots(limit: Int, assetId: String, destination: String, tag: String, completion: @escaping (MixinAPI.Result<[Snapshot]>) -> Void) {
        request(method: .get, path: Path.snapshots(limit: limit, assetId: assetId, destination: destination, tag: tag), completion: completion)
    }
    
    public static func snapshots(limit: Int, assetId: String, completion: @escaping (MixinAPI.Result<[Snapshot]>) -> Void) {
        request(method: .get, path: Path.snapshots(limit: limit, offset: nil, assetId: assetId, opponentId: nil), completion: completion)
    }
    
    public static func pendingDeposits(assetId: String, destination: String, tag: String, completion: @escaping (MixinAPI.Result<[PendingDeposit]>) -> Void) {
        request(method: .get, path: Path.pendingDeposits(assetId: assetId, destination: destination, tag: tag), completion: completion)
    }
    
    public static func search(keyword: String) -> MixinAPI.Result<[MixinToken]>  {
        guard let url = Path.search(keyword: keyword) else {
            return .success([])
        }
        return request(method: .get, path: url)
    }
    
    public static func search(
        keyword: String,
        queue: DispatchQueue,
        completion: @escaping (MixinAPI.Result<[MixinToken]>) -> Void
    ) -> Request? {
        guard let url = Path.search(keyword: keyword) else {
            queue.async {
                completion(.success([]))
            }
            return nil
        }
        return request(method: .get, path: url, queue: queue, completion: completion)
    }
    
    public static func topAssets(completion: @escaping (MixinAPI.Result<[TopAsset]>) -> Void) {
        request(method: .get, path: Path.top, completion: completion)
    }
    
    public static func ticker(asset: String, offset: String, completion: @escaping (MixinAPI.Result<TickerResponse>) -> Void) {
        request(method: .get, path: "/ticker?asset=\(asset)&offset=\(offset)", completion: completion)
    }
    
    public static func chains(completion: @escaping (MixinAPI.Result<[Chain]>) -> Void) {
        request(method: .get, path: Path.chains, completion: completion)
    }
    
    public static func chain(chainId: String, completion: @escaping (MixinAPI.Result<Chain>) -> Void) {
        request(method: .get, path: Path.chain(chainId: chainId), completion: completion)
    }
    
    public static func chain(chainId: String) -> MixinAPI.Result<Chain> {
        return request(method: .get, path: Path.chain(chainId: chainId))
    }
    
}
