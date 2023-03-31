pragma solidity ^0.8.0;

library model {
    // 内容类型枚举
    enum ContentType {
        OPEN,           // 开放型
        RESTRICTED      // 限定型
    }

    // 内容状态枚举
    enum ContentStatus {
        ENABLE,         // 启用
        FORBIDDEN,      // 禁用
        COMPLETED       // 已完成
    }

    // 申请条件结构体
    struct RequestQualification {
        uint256 id;
        uint256 flows;
        string[] tags;
        //        uint256 before;
        //        uint256 after;
    }

    // 领取奖励条件结构体
    struct ClaimQualification {
        uint256 id;
        uint256 likes;
        uint256 comments;
        uint256 mirrors;
        //        uint256 before;
        //        uint256 after;
    }

    // 内容结构体
    struct Content {
        uint256 id;
        address promoter;
        string headline;
        string description;
        ContentType typ;
        ContentStatus status;
        uint256 budget;
        string url;
        string previewUrl;
        uint256 total;
        uint256 createTime;
        ContentData data;
    }

    // 内容数据
    struct ContentData {
        uint256 requestedCnt;
        uint256 completedCnt;
        uint256 balance;
        uint256 requestQualificationId;
        uint256 claimQualificationId;
    }

    struct ContentDto {
        string headline;
        string description;
        ContentType typ;
        ContentStatus status;
        uint256 budget;
        string url;
        string previewUrl;
        uint256 total;
    }

    struct RequestQualificationDto {
        uint256 flows;
        string[] tags;
    }

    struct ClaimQualificationDto {
        uint256 likes;
        uint256 comments;
        uint256 mirrors;
    }

    struct PublishContentDto {
        ContentDto contentDto;
        RequestQualificationDto requestDto;
        ClaimQualificationDto claimDto;
    }

    struct ContentQueryCondition {
        address addr;
        PageQueryCondition pageCondition;
    }

    struct PageQueryCondition {
        // 当前页面
        uint pageIndex;
        // 每页数据条数
        uint pageSize;
        // 是否逆序
        bool isDescend;
    }

    struct BroadcasterClaimed {
        address broadcaster;
        bool claimed;
    }
}
