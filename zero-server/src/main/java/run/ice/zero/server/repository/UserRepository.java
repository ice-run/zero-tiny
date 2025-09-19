package run.ice.zero.server.repository;

import lombok.NonNull;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;
import run.ice.zero.server.entity.User;

import java.util.Optional;

/**
 * @author DaoDao
 */
@Repository
public interface UserRepository extends JpaRepository<@NonNull User, @NonNull Long>, JpaSpecificationExecutor<@NonNull User> {

    /**
     * 根据用户名查找用户
     *
     * @param username 要搜索的用户名
     * @return 如果找到，则返回包含 User 的 Optional 对象，否则返回空 Optional
     */
    Optional<User> findByUsername(@NonNull String username);

}
