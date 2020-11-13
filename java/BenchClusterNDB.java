import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.*;
import java.text.*;

public class BenchClusterNDB {

        private final static int MAX_RECORD = 68000000;
        private final static int NUM_ITER = 10000000;
        private SimpleDateFormat df = new SimpleDateFormat("dd/MM/yyyy HH:mm:ss.S");
        private Date beginTime;
        private Date endTime;
        private long minTime = 0;
        private long maxTime = 10;

        private void begin(){
                beginTime = new Date(System.currentTimeMillis());
        }

        private void end(){
                endTime = new Date(System.currentTimeMillis());
        }

        private Connection getConnection() throws ClassNotFoundException,SQLException {
                Connection conn = null;
                Class.forName("com.mysql.jdbc.Driver");
                conn = DriverManager.getConnection("jdbc:mysql://127.0.0.1:3306/zillow?"
                                + "user=root");
                return conn;
        }


        private void updateLoop() throws ClassNotFoundException,SQLException{
                Connection conn = null;
                PreparedStatement u_pstmt = null;
                PreparedStatement s_pstmt = null;
                try{
                        conn = getConnection();
                        u_pstmt = conn.prepareStatement(
                                        "update counter set hits0=hits0+1, sequence=sequence+1 where propertyid=?");
                        s_pstmt = conn.prepareStatement(
                                        "select hits0 from counter where propertyid=?");

                        for (int i=0;i<NUM_ITER;i++){
                                int rand = (int) (Math.random() * MAX_RECORD);
                                u_pstmt.setInt(1, rand);
                                s_pstmt.setInt(1, rand);

                                long inner_bt = System.currentTimeMillis();
                                u_pstmt.executeUpdate();
                                s_pstmt.executeQuery();
                                long inner_at = System.currentTimeMillis();
                                long timeDiff = inner_at - inner_bt;
                            if (timeDiff < minTime){
                                minTime = timeDiff;
                            }
                            else if (timeDiff > maxTime){
                                maxTime = timeDiff;
                            }
                        }
                }finally{
                        if(u_pstmt != null)u_pstmt.close();
                        if(s_pstmt != null)s_pstmt.close();
                        if(conn != null)conn.close();
                }
        }

        private void printReport(){
                System.out.println("Update time for " + NUM_ITER + " ");
                System.out.println( df.format(beginTime) + " -- " + df.format(endTime)
                                 + " = " + (endTime.getTime() - beginTime.getTime()) + "ms");
                System.out.println("Max time = " + maxTime + "ms");
                System.out.println("Min time = " + minTime + "ms");
        }

        public static void main(String args[]) throws ClassNotFoundException,SQLException{
                NdbUpdate1 n = new NdbUpdate1();
                n.begin();
                n.updateLoop();
                n.end();
                n.printReport();
        }

}