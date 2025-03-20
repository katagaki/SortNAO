//
//  Response.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/17.
//

extension SauceNAO {
    // swiftlint:disable nesting
    struct Response: Codable {
        var header: Header
        var results: [Result]

        struct Header: Codable {
            var userId: String
            var accountType: String
            var shortLimit: String
            var longLimit: String
            var longRemaining: Int
            var shortRemaining: Int
            var status: Int
            var resultsRequested: Int
            var index: [String: Index]
            var searchDepth: String
            var minimumSimilarity: Double
            var queryImageDisplay: String
            var queryImage: String
            var resultsReturned: Int

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case accountType = "account_type"
                case shortLimit = "short_limit"
                case longLimit = "long_limit"
                case longRemaining = "long_remaining"
                case shortRemaining = "short_remaining"
                case status = "status"
                case resultsRequested = "results_requested"
                case index = "index"
                case searchDepth = "search_depth"
                case minimumSimilarity = "minimum_similarity"
                case queryImageDisplay = "query_image_display"
                case queryImage = "query_image"
                case resultsReturned = "results_returned"
            }

            struct Index: Codable {
                var status: Int
                var parentId: Int
                var id: Int
                var results: Int

                enum CodingKeys: String, CodingKey {
                    case status = "status"
                    case parentId = "parent_id"
                    case id = "id"
                    case results = "results"
                }
            }
        }

        struct Result: Codable {
            var header: Header
            var data: Data

            struct Header: Codable {
                var similarity: String
                var thumbnail: String
                var indexId: Int
                var indexName: String
                var dupes: Int
                var hidden: Int

                enum CodingKeys: String, CodingKey {
                    case similarity = "similarity"
                    case thumbnail = "thumbnail"
                    case indexId = "index_id"
                    case indexName = "index_name"
                    case dupes = "dupes"
                    case hidden = "hidden"
                }

                func similarityValue() -> Double {
                    return Double(similarity) ?? .zero
                }
            }

            struct Data: Codable {
                var externalURLs: [String]

                // Danbooru/Gelbooru
                var danbooruId: Int?
                var gelbooruId: Int?
                var creator: String?
                var material: String?
                var characters: String?
                var source: String?

                // pixiv
                var title: String?
                var pixivId: Int?
                var memberName: String?
                var memberId: Int?

                // X
                var createdAt: String?
                var postId: String?
                var xUserId: String?
                var xUserHandle: String?

                enum CodingKeys: String, CodingKey {
                    case externalURLs = "ext_urls"
                    case danbooruId = "danbooru_id"
                    case gelbooruId = "gelbooru_id"
                    case creator = "creator"
                    case material = "material"
                    case characters = "characters"
                    case source = "source"
                    case title = "title"
                    case pixivId = "pixiv_id"
                    case memberName = "member_name"
                    case memberId = "member_id"
                    case createdAt = "created_at"
                    case postId = "tweet_id"
                    case xUserId = "twitter_user_id"
                    case xUserHandle = "twitter_user_handle"
                }
            }
        }
    }
    // swiftlint:enable nesting
}
