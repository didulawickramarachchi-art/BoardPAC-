package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.news.*;
import com.portSrilanka.board_admin_backend.entity.*;
import com.portSrilanka.board_admin_backend.exception.ResourceNotFoundException;
import com.portSrilanka.board_admin_backend.exception.BadRequestException;
import com.portSrilanka.board_admin_backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;
import java.util.stream.Collectors;

@Service @RequiredArgsConstructor
public class NewsService {
    private final NewsPostRepository posts; private final NewsCommentRepository comments;
    private final NewsReactionRepository reactions; private final UserRepository users;

    @Transactional(readOnly = true)
    public List<NewsResponse> getAll(String username) {
        User current = user(username); List<NewsPost> all = posts.findAllByOrderByDisplayOrderDescCreatedAtDesc();
        if (all.isEmpty()) return List.of();
        List<Long> ids = all.stream().map(NewsPost::getId).toList();
        Map<Long,List<NewsComment>> cs = comments.findByPostIdInOrderByCreatedAtAsc(ids).stream().collect(Collectors.groupingBy(x -> x.getPost().getId()));
        Map<Long,List<NewsReaction>> rs = reactions.findByPostIdIn(ids).stream().collect(Collectors.groupingBy(x -> x.getPost().getId()));
        return all.stream().map(p -> map(p, current.getId(), cs.getOrDefault(p.getId(), List.of()), rs.getOrDefault(p.getId(), List.of()))).toList();
    }

    @Transactional public NewsResponse create(NewsRequest request, String username) {
        String title = clean(request.getTitle()); String content = clean(request.getContent());
        validate(title, content);
        int nextOrder = posts.findAll().stream().map(NewsPost::getDisplayOrder).filter(Objects::nonNull).max(Integer::compareTo).orElse(0) + 1;
        List<String> imageUrls = images(request);
        NewsPost post = posts.save(NewsPost.builder().title(title).content(content).imageUrl(imageUrls.isEmpty() ? "" : imageUrls.get(0)).imageUrls(imageUrls).displayOrder(nextOrder).createdBy(user(username)).build());
        return map(post, post.getCreatedBy().getId(), List.of(), List.of());
    }
    @Transactional public NewsResponse update(Long id, NewsRequest request, String username) {
        NewsPost post = post(id); String title=clean(request.getTitle()), content=clean(request.getContent());
        validate(title, content);
        List<String> imageUrls = images(request);
        post.setTitle(title); post.setContent(content); post.setImageUrl(imageUrls.isEmpty() ? "" : imageUrls.get(0)); post.setImageUrls(imageUrls);
        posts.save(post); return one(post,user(username).getId());
    }
    @Transactional public void delete(Long id) { posts.delete(post(id)); }
    @Transactional public void reorder(NewsRequest request) {
        List<Long> ids=request.getOrderedIds(); if(ids==null)return; int order=ids.size();
        for(Long id:ids){NewsPost post=post(id);post.setDisplayOrder(order--);posts.save(post);}
    }
    @Transactional public NewsResponse comment(Long id, NewsRequest request, String username) {
        NewsPost post = post(id); User user = user(username); String message = clean(request.getMessage());
        if (message.isEmpty()) throw new IllegalArgumentException("Comment is required");
        comments.save(NewsComment.builder().post(post).user(user).message(message).build()); return one(post, user.getId());
    }
    @Transactional public NewsResponse react(Long id, NewsRequest request, String username) {
        NewsPost post = post(id); User user = user(username); String type = clean(request.getReactionType()).toUpperCase();
        if (!Set.of("LIKE","LOVE","CELEBRATE").contains(type)) throw new IllegalArgumentException("Invalid reaction");
        NewsReaction old = reactions.findByPostIdAndUserId(id, user.getId()).orElse(null);
        if (old != null && old.getReactionType().equals(type)) reactions.delete(old);
        else if (old != null) { old.setReactionType(type); reactions.save(old); }
        else reactions.save(NewsReaction.builder().post(post).user(user).reactionType(type).build());
        return one(post, user.getId());
    }
    private NewsResponse one(NewsPost p, Long userId) { return map(p,userId,comments.findByPostIdInOrderByCreatedAtAsc(List.of(p.getId())),reactions.findByPostIdIn(List.of(p.getId()))); }
    private NewsResponse map(NewsPost p, Long userId, List<NewsComment> cs, List<NewsReaction> rs) {
        Map<String,Long> counts=rs.stream().collect(Collectors.groupingBy(NewsReaction::getReactionType,Collectors.counting()));
        String mine=rs.stream().filter(r->r.getUser().getId().equals(userId)).map(NewsReaction::getReactionType).findFirst().orElse(null);
        User by=p.getCreatedBy();
        List<String> imageUrls = p.getImageUrls() == null || p.getImageUrls().isEmpty()
                ? (clean(p.getImageUrl()).isEmpty() ? List.of() : List.of(p.getImageUrl()))
                : List.copyOf(p.getImageUrls());
        return NewsResponse.builder().id(p.getId()).title(p.getTitle()).content(p.getContent()).imageUrl(imageUrls.isEmpty() ? null : imageUrls.get(0)).imageUrls(imageUrls).createdByUserId(by.getId()).createdByName(name(by)).createdByProfilePictureUrl(by.getProfilePictureUrl()).createdAt(p.getCreatedAt()).reactionCounts(counts).currentReaction(mine).comments(cs.stream().map(c->NewsResponse.Comment.builder().id(c.getId()).userId(c.getUser().getId()).userName(name(c.getUser())).profilePictureUrl(c.getUser().getProfilePictureUrl()).message(c.getMessage()).createdAt(c.getCreatedAt()).build()).toList()).build();
    }
    private User user(String username) { return users.findByUsername(username).orElseThrow(()->new ResourceNotFoundException("User not found")); }
    private NewsPost post(Long id) { return posts.findById(id).orElseThrow(()->new ResourceNotFoundException("News post not found")); }
    private String clean(String s) { return s == null ? "" : s.trim(); }
    private void validate(String title, String content) {
        if (title.isEmpty() || content.isEmpty()) throw new BadRequestException("News content is required");
        if (title.length() > 300) throw new BadRequestException("News headline must be 300 characters or fewer");
        if (content.length() > 100000) throw new BadRequestException("News content must be 100,000 characters or fewer");
    }
    private List<String> images(NewsRequest request) {
        List<String> values = request.getImageUrls();
        if (values == null) values = clean(request.getImageUrl()).isEmpty() ? List.of() : List.of(request.getImageUrl());
        List<String> cleaned = values.stream().map(this::clean).filter(s -> !s.isEmpty()).distinct().toList();
        if (cleaned.size() > 10) throw new BadRequestException("A news post can contain up to 10 images");
        return new ArrayList<>(cleaned);
    }
    private String name(User u) { return u.getDisplayName()!=null&&!u.getDisplayName().isBlank()?u.getDisplayName():(u.getFirstName()+" "+u.getLastName()).trim(); }
}
