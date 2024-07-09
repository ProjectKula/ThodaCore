//
//  DataLoaders.swift
//
//
//  Created by Shrish Deshpande on 03/07/24.
//

import Vapor
import Fluent
import DataLoader

class DataLoaders {
    public let request: Request

    // MARK: - User
    
    public lazy var users: DataLoader<Int, RegisteredUser> = DataLoader<Int, RegisteredUser>() { keys in
        return RegisteredUser.query(on: self.request.db)
          .filter(\.$id ~~ keys)
          .all()
          .map { users in
              keys.map { key in
                  DataLoaderFutureValue.success(users.first { $0.id! == key }!)
              }
          }
    }

    public lazy var followers: DataLoader<Int, Int> = DataLoader<Int, Int>() { keys in
        return Follower.query(on: self.request.db)
          .filter(\.$followed.$id ~~ keys)
          .all()
          .map { followers in
              keys.map { key in
                  DataLoaderFutureValue.success(followers.filter { $0.$followed.id == key }.count)
              }
          }
    }

    public lazy var following: DataLoader<Int, Int> = DataLoader<Int, Int>() { keys in
        return Follower.query(on: self.request.db)
          .filter(\.$follower.$id ~~ keys)
          .all()
          .map { following in
              keys.map { key in
                  DataLoaderFutureValue.success(following.filter { $0.$follower.id == key }.count)
              }
          }
    }

    public lazy var badges: DataLoader<Int, [Badge]> = DataLoader<Int, [Badge]>() { keys in
        return Badge.query(on: self.request.db)
          .filter(\.$user.$id ~~ keys)
          .all()
          .map { badges in
              keys.map { key in
                  DataLoaderFutureValue.success(badges.filter { $0.$user.id == key })
              }
          }
    }

    // MARK: - Post

    public lazy var confessions: DataLoader<Int, Confession> = DataLoader<Int, Confession>() { keys in
        return Confession.query(on: self.request.db)
          .filter(\.$id ~~ keys)
          .all()
          .map { confessions in
              keys.map { key in
                  DataLoaderFutureValue.success(confessions.first { $0.id! == key }!)
              }
          }
    }

    public lazy var posts: DataLoader<String, Post> = DataLoader<String, Post>() { keys in
        return Post.query(on: self.request.db)
          .filter(\.$id ~~ keys)
          .all()
          .map { posts in
              keys.map { key in
                  DataLoaderFutureValue.success(posts.first { $0.id! == key }!)
              }
          }
    }

    // TODO: cache likes count?
    public lazy var postLikes: DataLoader<String, Int> = DataLoader<String, Int>() { keys in
        return LikedPost.query(on: self.request.db)
          .filter(\.$post.$id ~~ keys)
          .all()
          .map { likes in
              keys.map { key in
              DataLoaderFutureValue.success(likes.filter { $0.$post.id == key }.count)
          }
      }
    }

    public lazy var attachments: DataLoader<String, [Attachment]> = DataLoader<String, [Attachment]>() { keys in
        return Attachment.query(on: self.request.db)
          .filter(\.$parentId ~~ keys)
          .all()
          .map { attachments in
              keys.map { key in
                  DataLoaderFutureValue.success(attachments.filter { $0.parentId == key })
              }
          }
    }

    public init(on request: Request) {
        self.request = request
    }
}

struct DataLoadersStorageKey: StorageKey {
    typealias Value = DataLoaders
}
