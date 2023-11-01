package com.mp.piggymetrics.statistics.repository;

import com.mp.piggymetrics.statistics.domain.timeseries.DataPoint;
import com.mp.piggymetrics.statistics.domain.timeseries.DataPointId;
import jakarta.data.repository.CrudRepository;
import jakarta.data.repository.Param;
import jakarta.data.repository.Query;
import jakarta.data.repository.Repository;

import java.util.List;

@Repository
public interface DataPointRepository extends CrudRepository<DataPoint, DataPointId> {
    @Query("select * from DataPoint where id.account = @account")
    List<DataPoint> findByIdAccount(@Param("account") String account);
}
