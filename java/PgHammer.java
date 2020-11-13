package com.opxdev.pghammer;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.text.*;
import java.util.*;

public class PreparedHammer
{
	private final static int MAX_RECORD = 9998;
	private final static int QUERY_TOTAL = 10;
	private SimpleDateFormat dateFormat = new SimpleDateFormat("dd/MM/yyyy HH:mm:ss.S");
	private Date beginTime;
	private Date endTime;
	private long minTime = 100;
	private long maxTime = 0;

	private void markStartTime()
	{
		beginTime = new Date(System.currentTimeMillis());
	}

	private void markEndTime()
	{
		endTime = new Date(System.currentTimeMillis());
	}

	private PreparedStatement createDatabaseConnection()
	{
		Connection conn = null;
		PreparedStatement preparedStatement = null;
		try
		{
			Class.forName("org.postgresql.Driver");
			conn = DriverManager.getConnection("jdbc:postgresql://st-cw20-pgdb3:5432/rdba", "hammeruser", "hammer");
			preparedStatement = conn.prepareStatement("select callbackdetail from hammer.callbackparams where jobid = ?;");
			for (int i = 0; i < QUERY_TOTAL; i++)
			{
				launchHammer(preparedStatement);
			}
		}
		catch (ClassNotFoundException cnfe)
		{
			cnfe.getException();
			System.out.println("Can't find the PostgreSQL JDBC Driver ");
		}
		catch (SQLException se)
		{
			se.getErrorCode();
			System.out.println("PreparedStatement creation failed");
		}
		return preparedStatement;
	}

	private void printReport()
	{
		System.out.println("Select time for " + QUERY_TOTAL + " iterations");
		System.out.println(dateFormat.format(beginTime) + " -- " + dateFormat.format(endTime) + " = "
						   + (endTime.getTime() - beginTime.getTime()) + "ms");
		System.out.println("Max time = " + maxTime + "ms");
		System.out.println("Min time = " + minTime + "ms");
	}

	private void launchHammer(PreparedStatement preparedStatement)
	{
		PreparedStatement hammerStatement = preparedStatement;
		try
		{
			int rand = (int) (Math.random() * MAX_RECORD);
			hammerStatement.setInt(1, rand);
			long startTime = System.currentTimeMillis();
			ResultSet resultSet = null;
			resultSet = hammerStatement.executeQuery();
			while (resultSet.next())
			{
				System.out.println(resultSet.getString(1));
			}
			long endTime = System.currentTimeMillis();
			long timeDiff = endTime - startTime;
			if (minTime > timeDiff)
			{
				minTime = timeDiff;
			}
			else if (maxTime < timeDiff)
			{
				maxTime = timeDiff;
			}
		} catch (SQLException se) {
			se.getErrorCode();
			System.out.println("LaunchHammer Failed!");
		}
		try {
			if (hammerStatement != null ) { hammerStatement.close(); };
		} catch (SQLException se) {
			se.getErrorCode();
			System.out.println("Close LaunchHammer connection failed!");
		} 
	}	
		
	public static void main(String args[])
	{
		PreparedHammer ph = new PreparedHammer();
		ph.markStartTime();
		PreparedStatement ps = ph.createDatabaseConnection();
		ph.launchHammer(ps);
		ph.markEndTime();
		ph.printReport();
	}
}