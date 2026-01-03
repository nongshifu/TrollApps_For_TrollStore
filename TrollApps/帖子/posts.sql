-- phpMyAdmin SQL Dump
-- version 5.0.4
-- https://www.phpmyadmin.net/
--
-- 主机： localhost
-- 生成日期： 2026-01-01 18:54:49
-- 服务器版本： 5.7.40-log
-- PHP 版本： 7.4.33

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- 数据库： `trollapps`
--

-- --------------------------------------------------------

--
-- 表的结构 `posts`
--

CREATE TABLE `posts` (
  `post_id` int(10) UNSIGNED NOT NULL COMMENT '帖子ID（数据库主键，自增）',
  `post_uuid` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '帖子唯一UUID（跨端/跨库兼容）',
  `post_title` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '帖子标题（可选，短文本）',
  `post_dir` text COLLATE utf8mb4_unicode_ci COMMENT '文件目录',
  `category_id` int(10) UNSIGNED DEFAULT '0' COMMENT '帖子分类ID（关联分类表）',
  `topic_ids` json DEFAULT NULL COMMENT '帖子标签ID数组（NSArray<NSNumber *>）',
  `post_content` text COLLATE utf8mb4_unicode_ci COMMENT '帖子正文（富文本/纯文本，支持HTML）',
  `post_images` json DEFAULT NULL COMMENT '图片URL数组（原图地址）',
  `post_images_thumb` json DEFAULT NULL COMMENT '图片缩略图URL数组（和post_images一一对应）',
  `post_video_url` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '视频URL（原视频地址）',
  `post_video_thumb_url` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '视频封面URL',
  `post_video_duration` decimal(10,2) DEFAULT '0.00' COMMENT '视频时长（秒，保留2位小数）',
  `post_video_size` bigint(20) UNSIGNED DEFAULT '0' COMMENT '视频文件大小（字节）',
  `post_attachments` json DEFAULT NULL COMMENT '附件模型数组（PostAttachmentModel）',
  `post_location` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '地理位置（如：北京市朝阳区）',
  `post_latlng` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '经纬度（格式："lat,lng"）',
  `user_id` int(10) UNSIGNED NOT NULL COMMENT '发布者用户ID（关联用户表user的user_id）',
  `user_model` json DEFAULT NULL COMMENT '发布者用户信息（缓存，与user表同步）',
  `post_create_time` bigint(20) UNSIGNED NOT NULL COMMENT '帖子创建时间（时间戳，秒级）',
  `post_update_time` bigint(20) UNSIGNED NOT NULL COMMENT '帖子更新时间（时间戳，秒级）',
  `post_publish_time` bigint(20) UNSIGNED DEFAULT '0' COMMENT '帖子发布时间（时间戳，审核通过后）',
  `post_last_comment_time` bigint(20) UNSIGNED DEFAULT '0' COMMENT '最后评论时间（时间戳）',
  `post_sort_weight` int(10) UNSIGNED DEFAULT '0' COMMENT '排序权重（数值越大越靠前）',
  `post_sort_type` tinyint(3) UNSIGNED DEFAULT '0' COMMENT '排序类型（0-创建时间 1-热度 2-推荐 3-最后评论）',
  `post_status` tinyint(3) UNSIGNED DEFAULT '0' COMMENT '帖子状态（0-草稿 1-待审核 2-已发布 3-已下架 4-已删除）',
  `post_audit_status` tinyint(3) UNSIGNED DEFAULT '0' COMMENT '审核状态（0-未审核 1-审核通过 2-审核驳回）',
  `post_reject_reason` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '驳回原因（审核不通过时填写）',
  `post_audit_count` int(10) UNSIGNED DEFAULT '0' COMMENT '审核次数',
  `post_is_top` tinyint(1) DEFAULT '0' COMMENT '是否置顶（0-否 1-是）',
  `post_is_hot` tinyint(1) DEFAULT '0' COMMENT '是否热门（0-否 1-是）',
  `post_is_recommend` tinyint(1) DEFAULT '0' COMMENT '是否推荐（0-否 1-是）',
  `post_visibility` tinyint(3) UNSIGNED DEFAULT '0' COMMENT '可见范围（0-公开 1-仅粉丝 2-仅自己）',
  `post_is_comment_forbidden` tinyint(1) DEFAULT '0' COMMENT '是否禁止评论（0-允许 1-禁止）',
  `post_is_share_forbidden` tinyint(1) DEFAULT '0' COMMENT '是否禁止分享（0-允许 1-禁止）',
  `post_view_count` int(10) UNSIGNED DEFAULT '0' COMMENT '浏览数',
  `post_like_count` int(10) UNSIGNED DEFAULT '0' COMMENT '点赞数',
  `post_comment_count` int(10) UNSIGNED DEFAULT '0' COMMENT '评论数',
  `post_share_count` int(10) UNSIGNED DEFAULT '0' COMMENT '分享数',
  `post_collect_count` int(10) UNSIGNED DEFAULT '0' COMMENT '收藏数',
  `post_report_count` int(10) UNSIGNED DEFAULT '0' COMMENT '举报数',
  `post_is_liked` tinyint(1) DEFAULT '0' COMMENT '当前用户是否点赞（前端展示用）',
  `post_is_collected` tinyint(1) DEFAULT '0' COMMENT '当前用户是否收藏（前端展示用）',
  `post_extra` json DEFAULT NULL COMMENT '扩展字段（自定义字典数据）'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='社区帖子主表';

--
-- 转储表的索引
--

--
-- 表的索引 `posts`
--
ALTER TABLE `posts`
  ADD PRIMARY KEY (`post_id`),
  ADD UNIQUE KEY `uk_post_uuid` (`post_uuid`),
  ADD KEY `idx_post_create_time` (`post_create_time`),
  ADD KEY `idx_post_sort_weight` (`post_sort_weight`),
  ADD KEY `idx_post_status` (`post_status`),
  ADD KEY `idx_post_user_id` (`user_id`);

--
-- 在导出的表使用AUTO_INCREMENT
--

--
-- 使用表AUTO_INCREMENT `posts`
--
ALTER TABLE `posts`
  MODIFY `post_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '帖子ID（数据库主键，自增）', AUTO_INCREMENT=73;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
