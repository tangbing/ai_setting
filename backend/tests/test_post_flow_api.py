from __future__ import annotations

from fastapi.testclient import TestClient


def test_post_comment_reply_and_like_flow(
    client: TestClient,
    auth_headers: dict[str, str],
) -> None:
    create_post_response = client.post(
        "/api/v1/posts",
        headers=auth_headers,
        json={
            "contentText": "Integration post",
            "locationName": "Shenzhen",
            "topicText": "Assembly",
            "mediaList": [],
        },
    )
    assert create_post_response.status_code == 201
    post_payload = create_post_response.json()
    post_id = post_payload["postId"]
    assert post_payload["isMine"] is True
    assert post_payload["likeCount"] == 0
    assert post_payload["commentCount"] == 0

    list_response = client.get("/api/v1/posts?feed=newest&limit=20", headers=auth_headers)
    assert list_response.status_code == 200
    list_payload = list_response.json()
    assert len(list_payload["items"]) == 1
    assert list_payload["items"][0]["postId"] == post_id
    assert list_payload["items"][0]["isMine"] is True

    comment_response = client.post(
        f"/api/v1/posts/{post_id}/comments",
        headers=auth_headers,
        json={"content": "First comment"},
    )
    assert comment_response.status_code == 201
    comment_payload = comment_response.json()
    assert comment_payload["level"] == 1
    comment_id = comment_payload["commentId"]

    reply_response = client.post(
        f"/api/v1/comments/{comment_id}/reply",
        headers=auth_headers,
        json={
            "content": "Reply comment",
            "replyToCommentId": comment_id,
        },
    )
    assert reply_response.status_code == 201
    reply_payload = reply_response.json()
    assert reply_payload["parentCommentId"] == comment_id
    assert reply_payload["rootCommentId"] == comment_id
    assert reply_payload["level"] == 2

    post_like_response = client.post(f"/api/v1/posts/{post_id}/like", headers=auth_headers)
    assert post_like_response.status_code == 200
    assert post_like_response.json()["likeCount"] == 1

    comment_like_response = client.post(
        f"/api/v1/comments/{comment_id}/like",
        headers=auth_headers,
    )
    assert comment_like_response.status_code == 200
    assert comment_like_response.json()["likeCount"] == 1

    detail_response = client.get(f"/api/v1/posts/{post_id}", headers=auth_headers)
    assert detail_response.status_code == 200
    detail_payload = detail_response.json()
    assert detail_payload["likeCount"] == 1
    assert detail_payload["commentCount"] == 2
    assert detail_payload["isLiked"] is True
    assert detail_payload["isMine"] is True

    comment_list_response = client.get(
        f"/api/v1/posts/{post_id}/comments?limit=30",
        headers=auth_headers,
    )
    assert comment_list_response.status_code == 200
    comment_list_payload = comment_list_response.json()
    assert len(comment_list_payload["items"]) == 1
    root_comment = comment_list_payload["items"][0]
    assert root_comment["commentId"] == comment_id
    assert root_comment["likeCount"] == 1
    assert root_comment["isLiked"] is True
    assert len(root_comment["replies"]) == 1
    assert root_comment["replies"][0]["content"] == "Reply comment"

    unlike_post_response = client.delete(f"/api/v1/posts/{post_id}/like", headers=auth_headers)
    assert unlike_post_response.status_code == 200

    unlike_comment_response = client.delete(
        f"/api/v1/comments/{comment_id}/like",
        headers=auth_headers,
    )
    assert unlike_comment_response.status_code == 200

    refreshed_detail_response = client.get(f"/api/v1/posts/{post_id}", headers=auth_headers)
    assert refreshed_detail_response.status_code == 200
    refreshed_detail = refreshed_detail_response.json()
    assert refreshed_detail["likeCount"] == 0
    assert refreshed_detail["isLiked"] is False


def test_post_create_accepts_media_type_image_default_and_explicit(
    client: TestClient,
    auth_headers: dict[str, str],
) -> None:
    explicit_response = client.post(
        "/api/v1/posts",
        headers=auth_headers,
        json={
            "contentText": "",
            "mediaList": [
                {
                    "mediaType": "image",
                    "url": "https://example.com/image-a.jpg",
                    "sortOrder": 1,
                }
            ],
        },
    )
    assert explicit_response.status_code == 201
    assert explicit_response.json()["mediaList"][0]["mediaType"] == "image"

    default_response = client.post(
        "/api/v1/posts",
        headers=auth_headers,
        json={
            "mediaList": [
                {
                    "url": "https://example.com/image-b.jpg",
                    "sortOrder": 1,
                }
            ],
        },
    )
    assert default_response.status_code == 201
    assert default_response.json()["mediaList"][0]["mediaType"] == "image"


def test_post_create_rejects_unsupported_media_type(
    client: TestClient,
    auth_headers: dict[str, str],
) -> None:
    response = client.post(
        "/api/v1/posts",
        headers=auth_headers,
        json={
            "mediaList": [
                {
                    "mediaType": "video",
                    "url": "https://example.com/video.mp4",
                    "sortOrder": 1,
                }
            ],
        },
    )

    assert response.status_code == 422


def test_posts_feed_requires_valid_feed_name(client: TestClient) -> None:
    response = client.get("/api/v1/posts?feed=invalid")

    assert response.status_code == 422
    assert response.json()["detail"] == "feed must be one of: newest, hot, following"
