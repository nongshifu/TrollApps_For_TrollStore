<?php
/**
 * 帖子管理API - 发布/删除/更新/搜索/排序等操作
 */
require_once '../Config.php';
Logger::setLoggingEnabled(true);

// 帖子基础状态
define('PostStatusDraft', 0);          // 草稿
define('PostStatusPublished', 1);      // 已发布
define('PostStatusPendingAudit', 2);   // 待审核
define('PostStatusRejected', 3);       // 审核驳回
define('PostStatusOffline', 4);        // 已下架

// 审核状态常量（补充，避免后续报错）
define('PostAuditStatusNotAudited', 0); // 未审核
define('PostAuditStatusApproved', 1);   // 已审核
define('PostAuditStatusRejected', 2);   // 审核驳回


// 排序
define('PostSortTypeCreateTime', 0);   // 创建时间
define('PostSortTypeHot', 1);          // 最热门
define('PostSortTypeRecommend', 2);    //推荐排行
define('PostSortTypeLastComment', 2);    //最后评论




// 跨域与响应头设置
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS, PUT, DELETE");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-UDID, X-Token");
header("Content-Type: application/json; charset=utf-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// 初始化数据库连接
$pdo = DB::getConnection();
//封装默认返回值
$response = ['code' => ERROR_SERVER, 'msg' => '服务器内部错误'];

//类型区分上传文件还是POST  GET
$contentType = $_SERVER['CONTENT_TYPE'] ?? '';


try {
    // 1. 解析请求数据（兼容表单和JSON）
    if (strpos($contentType, 'multipart/form-data') !== false) {
        $request = $_POST;
        // 兼容base64数据解析
        if (!empty($request['data'])) {
            $request['data'] = json_decode($request['data'], true) ?: [];
        }
    } else {
        $request = json_decode(file_get_contents('php://input'), true) ?: [];
    }

    // 2. 用户认证（部分接口需要）
    $udid = $request['udid'] ?? $_SERVER['HTTP_X_UDID'] ?? '';
    $token = $request['token'] ?? $_SERVER['HTTP_X_TOKEN'] ?? '';
    // 3. 效验token合法
    $validator = new TokenValidator($token, $udid);
    // 4 读取合法token后的用户数据
    $user = $validator->getUser();

    // 5. 路由分发（根据action参数）
    $action = $request['action'] ?? '';
    
    // 6. 读取主要请求体 udid 和 token 是封装在外面的 Post格式 $request = {'action':"actionStr",'token':"d738f322f",'udid':'TRWW-224-42-141','data':{}}
    // Logger::info("[request]  : ".json_encode($request));
    // $data = $request['data'] ?? '';
    
    Logger::info("全部请求体  : ".json_encode($request));

    switch ($action) {
        // 路由操作
        case 'publish_post':
            $response = handlePublishPost($pdo, $user, $request);
            break;
            
        case 'update_post':
            $response = handleUpdatePost($pdo, $user, $request);
            break;
            
        case 'search_posts':
            $response = handleSearchPosts($pdo, $user, $request);
            break;
            
        case 'delete_post':
            $response = handleDeletePost($pdo, $user, $request);
            break;
            
        case 'complete_publish':
            $response = handleCompletePublish($pdo, $user, $request);
            break;
            
        default:
            throw new Exception("无效的操作类型", ERROR_PARAMS);
    }
} catch (Exception $e) {
    $response['code'] = $e->getCode() ?: ERROR_SERVER;
    $response['msg'] = $e->getMessage();
    $userId = $validator->getUser()['user_id'] ?? '未知';
    Logger::error("帖子操作失败：用户ID={$userId}，错误={$e->getMessage()}");
}

echo json_encode($response, JSON_UNESCAPED_UNICODE);


/**
 * 发布帖子
 * @param PDO $pdo 数据库连接
 * @param array $user 用户信息
 * @param array $data 请求数据
 * @return array 响应数据
 */
function handlePublishPost($pdo, $user, $data) {
    Logger::setLoggingEnabled(true);
    
    Logger::info("[发布帖子]  : ".json_encode($data));
    // 发布帖子
    $title = $data['post_title'] ?? '';
    $content = $data['post_content'] ?? '';
    $visibility = $data['post_visibility'] ?? 0;
    $isCommentForbidden = $data['post_is_comment_forbidden'] ?? 0;
    $isShareForbidden = $data['post_is_share_forbidden'] ?? 0;
    $categoryId = $data['category_id'] ?? 0;
    $topicIds = $data['topic_ids'] ?? [];
    $images = $data['post_images'] ?? [];
    
    // 验证必填字段
    if (empty($title)) {
        throw new Exception("标题不能为空", ERROR_PARAMS);
    }
    
    // 创建帖子ID
    $postId = uniqid();
    $userId = $user['user_id'];
    
    // 创建帖子存储目录
    $postDir = "uploads/posts/{$userId}/{$postId}";
    $fullPostDir = $_SERVER['DOCUMENT_ROOT'] . '/' . $postDir;
    
    if (!file_exists($fullPostDir)) {
        $mkdirResult = mkdir($fullPostDir, 0755, true);
        if (!$mkdirResult) {
            throw new Exception("创建帖子目录失败", ERROR_SERVER);
        }
    }
    
    // 插入帖子数据
    $sql = "INSERT INTO posts (post_id, user_id, post_title, post_content, post_visibility, post_is_comment_forbidden, post_is_share_forbidden, category_id, topic_ids, post_images, post_status, created_at, updated_at) VALUES (:post_id, :user_id, :post_title, :post_content, :post_visibility, :post_is_comment_forbidden, :post_is_share_forbidden, :category_id, :topic_ids, :post_images, :post_status, NOW(), NOW())";
    $stmt = $pdo->prepare($sql);
    $stmt->bindValue(':post_id', $postId);
    $stmt->bindValue(':user_id', $userId);
    $stmt->bindValue(':post_title', $title);
    $stmt->bindValue(':post_content', $content);
    $stmt->bindValue(':post_visibility', $visibility);
    $stmt->bindValue(':post_is_comment_forbidden', $isCommentForbidden);
    $stmt->bindValue(':post_is_share_forbidden', $isShareForbidden);
    $stmt->bindValue(':category_id', $categoryId);
    $stmt->bindValue(':topic_ids', json_encode($topicIds));
    $stmt->bindValue(':post_images', json_encode($images));
    $stmt->bindValue(':post_status', PostStatusPublished);
    
    if (!$stmt->execute()) {
        throw new Exception("创建帖子失败", ERROR_SERVER);
    }
    
    // 获取刚创建的帖子
    $sql = "SELECT * FROM posts WHERE post_id = :post_id";
    $stmt = $pdo->prepare($sql);
    $stmt->bindValue(':post_id', $postId);
    $stmt->execute();
    $post = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // 解析JSON字段
    $post['post_images'] = json_decode($post['post_images'], true);
    $post['topic_ids'] = json_decode($post['topic_ids'], true);
    
    return [
        'code' => ERROR_SUCCESS,
        'msg' => "发布成功",
        'data' => $post
    ];
}

/**
 * 更新帖子
 * @param PDO $pdo 数据库连接
 * @param array $user 用户信息
 * @param array $data 请求数据
 * @return array 响应数据
 */
function handleUpdatePost($pdo, $user, $data) {
    // 更新帖子
    $postId = $data['post_id'] ?? '';
    $title = $data['post_title'] ?? '';
    $content = $data['post_content'] ?? '';
    $visibility = $data['post_visibility'] ?? 0;
    $isCommentForbidden = $data['post_is_comment_forbidden'] ?? 0;
    $isShareForbidden = $data['post_is_share_forbidden'] ?? 0;
    $categoryId = $data['category_id'] ?? 0;
    $topicIds = $data['topic_ids'] ?? [];
    $images = $data['post_images'] ?? [];
    
    // 验证必填字段
    if (empty($postId)) {
        throw new Exception("帖子ID不能为空", ERROR_PARAMS);
    }
    if (empty($title)) {
        throw new Exception("标题不能为空", ERROR_PARAMS);
    }
    
    // 更新帖子数据
    $sql = "UPDATE posts SET post_title = :post_title, post_content = :post_content, post_visibility = :post_visibility, post_is_comment_forbidden = :post_is_comment_forbidden, post_is_share_forbidden = :post_is_share_forbidden, category_id = :category_id, topic_ids = :topic_ids, post_images = :post_images, updated_at = NOW() WHERE post_id = :post_id";
    $stmt = $pdo->prepare($sql);
    $stmt->bindValue(':post_title', $title);
    $stmt->bindValue(':post_content', $content);
    $stmt->bindValue(':post_visibility', $visibility);
    $stmt->bindValue(':post_is_comment_forbidden', $isCommentForbidden);
    $stmt->bindValue(':post_is_share_forbidden', $isShareForbidden);
    $stmt->bindValue(':category_id', $categoryId);
    $stmt->bindValue(':topic_ids', json_encode($topicIds));
    $stmt->bindValue(':post_images', json_encode($images));
    $stmt->bindValue(':post_id', $postId);
    
    if (!$stmt->execute()) {
        throw new Exception("更新帖子失败", ERROR_SERVER);
    }
    
    // 获取更新后的帖子
    $sql = "SELECT * FROM posts WHERE post_id = :post_id";
    $stmt = $pdo->prepare($sql);
    $stmt->bindValue(':post_id', $postId);
    $stmt->execute();
    $post = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // 解析JSON字段
    $post['post_images'] = json_decode($post['post_images'], true);
    $post['topic_ids'] = json_decode($post['topic_ids'], true);
    
    return [
        'code' => ERROR_SUCCESS,
        'msg' => "更新成功",
        'data' => $post
    ];
}

/**
 * 分页搜索帖子
 * @param PDO $pdo 数据库连接
 * @param array $user 用户信息
 * @param array $data 请求数据
 * @return array 响应数据
 */
function handleSearchPosts($pdo, $user, $data) {
    // 分页搜索帖子
    $page = $data['page'] ?? 1;
    $pageSize = $data['page_size'] ?? 10;
    $keyword = $data['keyword'] ?? '';
    $sortType = $data['sort_type'] ?? PostSortTypeCreateTime;
    $categoryId = $data['category_id'] ?? null;
    $userId = $data['user_id'] ?? null;
    
    // 计算偏移量
    $offset = ($page - 1) * $pageSize;
    
    // 构建SQL查询
    $sql = "SELECT * FROM posts WHERE post_status = :post_status";
    $params = [':post_status' => PostStatusPublished];
    
    // 添加关键词搜索
    if (!empty($keyword)) {
        $sql .= " AND (post_title LIKE :keyword OR post_content LIKE :keyword)";
        $params[':keyword'] = "%{$keyword}%";
    }
    
    // 添加分类筛选
    if ($categoryId !== null) {
        $sql .= " AND category_id = :category_id";
        $params[':category_id'] = $categoryId;
    }
    
    // 添加用户筛选
    if ($userId !== null) {
        $sql .= " AND user_id = :user_id";
        $params[':user_id'] = $userId;
    }
    
    // 添加排序
    switch ($sortType) {
        case PostSortTypeHot:
            $sql .= " ORDER BY post_like_count DESC, post_comment_count DESC, created_at DESC";
            break;
        case PostSortTypeRecommend:
            $sql .= " ORDER BY post_recommend_count DESC, created_at DESC";
            break;
        case PostSortTypeLastComment:
            $sql .= " ORDER BY post_last_comment_time DESC, created_at DESC";
            break;
        default:
            $sql .= " ORDER BY created_at DESC";
            break;
    }
    
    // 添加分页
    $sql .= " LIMIT :offset, :page_size";
    $params[':offset'] = $offset;
    $params[':page_size'] = $pageSize;
    
    // 执行查询
    $stmt = $pdo->prepare($sql);
    
    // 绑定参数（需要处理整数类型）
    foreach ($params as $key => &$value) {
        if (is_int($value)) {
            $stmt->bindValue($key, $value, PDO::PARAM_INT);
        } else {
            $stmt->bindValue($key, $value);
        }
    }
    
    $stmt->execute();
    $posts = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // 解析JSON字段
    foreach ($posts as &$post) {
        $post['post_images'] = json_decode($post['post_images'], true);
        $post['topic_ids'] = json_decode($post['topic_ids'], true);
    }
    
    // 获取总记录数
    $countSql = "SELECT COUNT(*) FROM posts WHERE post_status = :post_status";
    $countParams = [':post_status' => PostStatusPublished];
    
    if (!empty($keyword)) {
        $countSql .= " AND (post_title LIKE :keyword OR post_content LIKE :keyword)";
        $countParams[':keyword'] = "%{$keyword}%";
    }
    
    if ($categoryId !== null) {
        $countSql .= " AND category_id = :category_id";
        $countParams[':category_id'] = $categoryId;
    }
    
    if ($userId !== null) {
        $countSql .= " AND user_id = :user_id";
        $countParams[':user_id'] = $userId;
    }
    
    $countStmt = $pdo->prepare($countSql);
    foreach ($countParams as $key => &$value) {
        if (is_int($value)) {
            $countStmt->bindValue($key, $value, PDO::PARAM_INT);
        } else {
            $countStmt->bindValue($key, $value);
        }
    }
    $countStmt->execute();
    $total = $countStmt->fetchColumn();
    
    // 计算总页数
    $totalPages = ceil($total / $pageSize);
    
    return [
        'code' => ERROR_SUCCESS,
        'msg' => "搜索成功",
        'data' => [
            'posts' => $posts,
            'total' => $total,
            'page' => $page,
            'page_size' => $pageSize,
            'total_pages' => $totalPages
        ]
    ];
}

/**
 * 删除帖子
 * @param PDO $pdo 数据库连接
 * @param array $user 用户信息
 * @param array $data 请求数据
 * @return array 响应数据
 */
function handleDeletePost($pdo, $user, $data) {
    // 删除帖子
    $postId = $data['post_id'] ?? '';
    
    // 验证必填字段
    if (empty($postId)) {
        throw new Exception("帖子ID不能为空", ERROR_PARAMS);
    }
    
    // 更新帖子状态为已下架
    $sql = "UPDATE posts SET post_status = :post_status, updated_at = NOW() WHERE post_id = :post_id AND user_id = :user_id";
    $stmt = $pdo->prepare($sql);
    $stmt->bindValue(':post_status', PostStatusOffline);
    $stmt->bindValue(':post_id', $postId);
    $stmt->bindValue(':user_id', $user['user_id']);
    
    if (!$stmt->execute()) {
        throw new Exception("删除帖子失败", ERROR_SERVER);
    }
    
    // 检查是否有记录被更新
    if ($stmt->rowCount() == 0) {
        throw new Exception("帖子不存在或无权限删除", ERROR_PARAMS);
    }
    
    return [
        'code' => ERROR_SUCCESS,
        'msg' => "删除成功"
    ];
}

/**
 * 完成发布
 * @param PDO $pdo 数据库连接
 * @param array $user 用户信息
 * @param array $data 请求数据
 * @return array 响应数据
 */
function handleCompletePublish($pdo, $user, $data) {
    // 完成发布
    $postId = $data['post_id'] ?? '';
    $cloudImageUrls = $data['post_images'] ?? [];
    $cloudAudioUrls = $data['post_audio_urls'] ?? [];
    
    // 验证必填字段
    if (empty($postId)) {
        throw new Exception("帖子ID不能为空", ERROR_PARAMS);
    }
    
    // 更新帖子状态为已发布
    $sql = "UPDATE posts SET post_status = :post_status, post_images = :post_images, post_audio_urls = :post_audio_urls, updated_at = NOW() WHERE post_id = :post_id";
    $stmt = $pdo->prepare($sql);
    $stmt->bindValue(':post_status', PostStatusPublished);
    $stmt->bindValue(':post_images', json_encode($cloudImageUrls));
    $stmt->bindValue(':post_audio_urls', json_encode($cloudAudioUrls));
    $stmt->bindValue(':post_id', $postId);
    
    if (!$stmt->execute()) {
        throw new Exception("更新帖子状态失败", ERROR_SERVER);
    }
    
    // 获取更新后的帖子
    $sql = "SELECT * FROM posts WHERE post_id = :post_id";
    $stmt = $pdo->prepare($sql);
    $stmt->bindValue(':post_id', $postId);
    $stmt->execute();
    $post = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // 解析JSON字段
    $post['post_images'] = json_decode($post['post_images'], true);
    $post['topic_ids'] = json_decode($post['topic_ids'], true);
    $post['post_audio_urls'] = json_decode($post['post_audio_urls'], true);
    
    return [
        'code' => ERROR_SUCCESS,
        'msg' => "发布完成",
        'data' => $post
    ];
}


?>
