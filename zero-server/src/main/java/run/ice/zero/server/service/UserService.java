package run.ice.zero.server.service;

import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.BeanUtils;
import org.springframework.data.domain.*;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import run.ice.zero.server.constant.CacheConstant;
import run.ice.zero.server.constant.ServerConstant;
import run.ice.zero.server.entity.FileInfo;
import run.ice.zero.server.entity.User;
import run.ice.zero.server.error.AppException;
import run.ice.zero.server.error.ServerError;
import run.ice.zero.server.model.IdParam;
import run.ice.zero.server.model.PageData;
import run.ice.zero.server.model.PageParam;
import run.ice.zero.server.model.user.UserData;
import run.ice.zero.server.model.user.UserSearch;
import run.ice.zero.server.model.user.UserUpdate;
import run.ice.zero.server.model.user.UserUpsert;
import run.ice.zero.server.repository.FileInfoRepository;
import run.ice.zero.server.repository.UserRepository;

import java.time.Duration;
import java.util.*;

/**
 * @author DaoDao
 */
@Slf4j
@Service
@Transactional
public class UserService implements UserDetailsService {

    @Resource
    private UserRepository userRepository;

    @Resource
    private PasswordEncoder passwordEncoder;

    @Resource
    private StringRedisTemplate stringRedisTemplate;

    @Resource
    private FileInfoRepository fileInfoRepository;

    /**
     * 根据用户名加载用户信息
     *
     * @param username 用户名
     * @return UserDetails 用户信息
     * @throws UsernameNotFoundException 用户名不存在异常
     */
    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        Optional<User> optional = userRepository.findByUsername(username);
        if (optional.isEmpty()) {
            throw new UsernameNotFoundException(ServerError.USERNAME_NOT_EXIST + ":" + username);
        }
        User user = optional.get();
        Set<GrantedAuthority> grantedAuthorities = getGrantedAuthoritiesByUser(user);
        return new org.springframework.security.core.userdetails.User(user.getUsername(), user.getPassword(), grantedAuthorities);
    }

    /**
     * 获取用户授权
     *
     * @param user User
     * @return Set
     */
    private Set<GrantedAuthority> getGrantedAuthoritiesByUser(User user) {
        assert null != user;
        String username = user.getUsername();
        Set<GrantedAuthority> grantedAuthorities = new HashSet<>();
        /*
         * tiny 系统将权限代码 admin 授权给 admin 用户
         * 将权限代码 user 授权给其它用户
         */
        List<String> permissions = new ArrayList<>();
        if (ServerConstant.ADMIN.equals(username)) {
            permissions.add(ServerConstant.ADMIN);
        }
        permissions.add(ServerConstant.USER);
        /*
         * 声明用户授权
         */
        permissions.forEach(permission -> {
            if (null != permission && !permission.isEmpty()) {
                GrantedAuthority grantedAuthority = new SimpleGrantedAuthority(permission);
                grantedAuthorities.add(grantedAuthority);
            }
        });
        permissions.clear();
        return grantedAuthorities;
    }

    public UserData userInfo() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();
        Optional<User> optional = userRepository.findByUsername(username);
        if (optional.isEmpty()) {
            throw new AppException(ServerError.USERNAME_NOT_EXIST, username);
        }
        User user = optional.get();
        UserData data = new UserData();
        BeanUtils.copyProperties(user, data);
        return data;
    }

    public UserData userUpdate(UserUpdate param) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();
        Optional<User> optional = userRepository.findByUsername(username);
        if (optional.isEmpty()) {
            throw new AppException(ServerError.USERNAME_NOT_EXIST, username);
        }
        User user = optional.get();
        String nickname = param.getNickname();
        if (null != nickname && !nickname.isEmpty()) {
            user.setNickname(nickname);
        }
        String avatar = param.getAvatar();
        if (null != avatar && !avatar.isEmpty()) {
            Optional<FileInfo> o = fileInfoRepository.findById(avatar);
            if (o.isEmpty()) {
                throw new AppException(ServerError.FILE_NOT_EXIST, avatar);
            }
            user.setAvatar(avatar);
        }
        user = userRepository.save(user);
        UserData data = new UserData();
        BeanUtils.copyProperties(user, data);
        return data;
    }

    public UserData userSelect(IdParam param) {
        Long id = param.getId();
        User model = user(id);
        UserData userData = new UserData();
        BeanUtils.copyProperties(model, userData);
        return userData;
    }

    public User user(Long id) {
        String key = CacheConstant.USER + id;
        String json = stringRedisTemplate.opsForValue().get(key);
        if (null != json) {
            return new User().ofJson(json);
        }
        Optional<User> optional = userRepository.findById(id);
        if (optional.isEmpty()) {
            throw new AppException(ServerError.USER_NOT_EXIST, String.valueOf(id));
        }
        User user = optional.get();
        stringRedisTemplate.opsForValue().set(key, user.toJson(), Duration.ofHours(1L));
        return user;
    }

    public UserData userUpsert(UserUpsert param) {
        Long id = param.getId();
        String username = param.getUsername();
        User entity;
        if (null == id) {
            if (null == username || username.isEmpty()) {
                throw new AppException(ServerError.USERNAME_NOT_NULL);
            }
            Optional<User> optional = userRepository.findByUsername(username);
            if (optional.isPresent()) {
                throw new AppException(ServerError.USERNAME_ALREADY_EXIST, username);
            }
            entity = new User();
            entity.setPassword(passwordEncoder.encode(username));
        } else {
            Optional<User> optional = userRepository.findById(id);
            if (optional.isEmpty()) {
                throw new AppException(ServerError.USER_NOT_EXIST, String.valueOf(id));
            }
            entity = optional.get();
            if (null != username && !username.isEmpty()) {
                Optional<User> o = userRepository.findByUsername(username);
                if (o.isPresent() && !o.get().getId().equals(id)) {
                    throw new AppException(ServerError.USERNAME_ALREADY_EXIST, username);
                }
            }
            // entity.setUpdateTime(LocalDateTime.now());
        }

        BeanUtils.copyProperties(param, entity);
        entity = userRepository.saveAndFlush(entity);

        String key = CacheConstant.USER + id;
        stringRedisTemplate.delete(key);

        UserData data = new UserData();
        BeanUtils.copyProperties(entity, data);
        return data;
    }

    public PageData<UserData> userSearch(PageParam<UserSearch> pageParam) {
        Integer page = pageParam.getPage();
        Integer size = pageParam.getSize();
        User model = new User();
        UserSearch param = pageParam.getParam();
        BeanUtils.copyProperties(param, model);
        ExampleMatcher matcher = ExampleMatcher.matching()
                .withMatcher("username", ExampleMatcher.GenericPropertyMatchers.contains());
        Example<User> example = Example.of(model, matcher);
        Sort sort = Sort.by(Sort.Direction.ASC, "id");
        Pageable pageable = PageRequest.of(page - 1, size, sort);
        Page<User> dataPage = userRepository.findAll(example, pageable);
        Long total = dataPage.getTotalElements();
        List<User> dataList = dataPage.getContent();
        List<UserData> list = dataList.stream().map(source -> {
            UserData target = new UserData();
            BeanUtils.copyProperties(source, target);
            return target;
        }).toList();
        return new PageData<>(page, size, total, list);
    }

}
