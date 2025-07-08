-- POST CATEGORY 
with category_kpi as (
SELECT category_id
    , user_level
    , count(DISTINCT post_nickname) as post_uniq_user  # 고유 유저수
    , count(post_id)                as post_cnt          # 게시글 수
    , ROUND(count(DISTINCT post_nickname)*100 / count(post_id)) as post_uniq_user_ratio # 고유한 유저수 비율

    , sum(post_view_cnt)            as post_view_sum     # 누적 조회수
    , sum(post_like_cnt)            as post_like_sum     # 누적 좋아요수
    , sum(post_comment_cnt)         as post_cmnt_sum     # 누적 댓글수
    
    , ROUND(avg(post_view_cnt),2)    as post_view_mean   # 평균 조회수
    , ROUND(avg(post_like_cnt),2)    as post_like_mean   # 평균 좋아요수
    , ROUND(avg(post_comment_cnt),2) as post_cmnt_mean   # 평균 댓글수
    
    , ROUND(avg(view_like_ratio),2)*100 as post_view_like_ratio    # 조회수 대비 좋아요 비율
    , ROUND(avg(view_cmnt_ratio),2)*100 as post_view_cmnt_ratio    # 조회수 대비 댓글 비율
FROM ( SELECT *
            , CASE WHEN post_nick_level = '느그자' THEN 'LV5' 
                   WHEN post_nick_level = '침팬치' THEN 'LV4'
                   WHEN post_nick_level = '왁무새' THEN 'LV3'
                   WHEN post_nick_level = '닭둘기' THEN 'LV2'
                   WHEN post_nick_level = '진드기' THEN 'LV1' ELSE post_nick_level END AS user_level
            , post_like_cnt/post_view_cnt    as view_like_ratio
            , post_comment_cnt/post_view_cnt as view_cmnt_ratio
       FROM CAFE.post) A
WHERE user_level NOT IN ('아메바','카페스탭')
GROUP BY category_id,  user_level),



-- COMMENT
# 작성자 정보 추가
comment_tbl AS (
SELECT *
    , CASE WHEN post_nickname = comment_nickname THEN 'auther' ELSE 'user' END AS comment_info
    , CASE WHEN comment_text is NULL then 'emoji' ELSE 'text' END as comment_content 
FROM (SELECT A.*
            ,B.post_nickname
            ,B.post_nick_level
        FROM CAFE.comment A
        JOIN CAFE.post B ON A.post_id = B.post_id ) cte
),

# intercation indicator 

II AS (
SELECT C.category_tag
     ,C.category_title
     ,A.*
FROM (SELECT category_id
            , COUNT(DISTINCT comment_nickname) as cmnt_uniq_user    # 댓글에 참여한 유저수
            , COUNT(*) as cmnt_cnt                                  # 전체 댓글수
            , SUM(comment_like_cnt) as cmnt_like_sum                # 댓글 좋아요수
            , SUM(CASE WHEN comment_content ='text' then 1 ELSE 0 END) AS text_cnt
            , SUM(CASE WHEN comment_info = 'auther' THEN 1 ELSE 0 END) AS author_reply                          # 게시글 작성자 답글수
            , ROUND(COUNT(DISTINCT comment_nickname)*100 / COUNT(comment_nickname)) as cmnt_uniq_user_ratio     # 고유한 유저 댓글 비율
            , ROUND(SUM(comment_like_cnt)*100 / COUNT(*)) as cmnt_like_ratio                                    # 댓글수 대비 받은 댓글 좋아요
            , ROUND(SUM(CASE WHEN comment_content ='text' then 1 ELSE 0 END)*100 / COUNT(*)) as cmnt_txt_ratio  # 댓글 내용(텍스트) 비율

        FROM comment_tbl
        GROUP BY category_id
        ) A
INNER JOIN CAFE.category C ON A.category_id = C.category_id),


-- Chapter2. 게시글 별 등급 참여도

static_level as (
SELECT B.category_tag 
    , B.category_title
    , user_level 
    , post_cnt
    , post_uniq_user
    , post_uniq_user_ratio
    , SUM(post_cnt) OVER(PARTITION BY category_title) as total_post_cnt
    , ROUND(SUM(post_uniq_user) OVER(PARTITION BY category_title)*100/ SUM(post_cnt) OVER(PARTITION BY category_title)) as category_uniq_ratio
FROM category_kpi A
JOIN CAFE.category B ON A.category_id = B.category_id
ORDER BY A.category_id, user_level)

SELECT *
FROM II








