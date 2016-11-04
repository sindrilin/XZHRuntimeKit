//
//  UserModel.m
//  XZHRuntimeDemo
//
//  Created by fenqile on 16/10/31.
//  Copyright © 2016年 com.cn.fql. All rights reserved.
//

#import "UserModel.h"

@implementation YYModelUserModel
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
             @"userID" : @"id",
             @"avatarURL" : @"avatar_url",
             @"gravatarID" : @"gravatar_id",
             @"htmlURL" : @"html_url",
             @"followersURL" : @"followers_url",
             @"followingURL" : @"following_url",
             @"gistsURL" : @"gists_url",
             @"starredURL" : @"starred_url",
             @"subscriptionsURL" : @"subscriptions_url",
             @"organizationsURL" : @"organizations_url",
             @"reposURL" : @"repos_url",
             @"eventsURL" : @"events_url",
             @"receivedEventsURL" : @"received_events_url",
             @"siteAdmin" : @"site_admin",
             @"publicRepos" : @"public_repos",
             @"publicGists" : @"public_gists",
             @"createdAt" : @"created_at",
             @"updatedAt" : @"updated_at",
             };
}
@end

@implementation XZHRuntimeUserModel
+ (NSDictionary *)xzh_customerPropertyNameMappingJSONKey {
    return @{
             @"userID" : @"id",
             @"avatarURL" : @"avatar_url",
             @"gravatarID" : @"gravatar_id",
             @"htmlURL" : @"html_url",
             @"followersURL" : @"followers_url",
             @"followingURL" : @"following_url",
             @"gistsURL" : @"gists_url",
             @"starredURL" : @"starred_url",
             @"subscriptionsURL" : @"subscriptions_url",
             @"organizationsURL" : @"organizations_url",
             @"reposURL" : @"repos_url",
             @"eventsURL" : @"events_url",
             @"receivedEventsURL" : @"received_events_url",
             @"siteAdmin" : @"site_admin",
             @"publicRepos" : @"public_repos",
             @"publicGists" : @"public_gists",
             @"createdAt" : @"created_at",
             @"updatedAt" : @"updated_at",
             };
}
@end