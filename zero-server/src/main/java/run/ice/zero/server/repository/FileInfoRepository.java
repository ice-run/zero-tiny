package run.ice.zero.server.repository;

import lombok.NonNull;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;
import run.ice.zero.server.entity.FileInfo;

/**
 * @author DaoDao
 */
@Repository
public interface FileInfoRepository extends JpaRepository<@NonNull FileInfo, @NonNull String>, JpaSpecificationExecutor<@NonNull FileInfo> {

}
