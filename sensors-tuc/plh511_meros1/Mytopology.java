package topology_package;

import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;

public class Mytopology {
	
public static int[][]makegrid(int D){
	int[][] matrix = new int[D][D];
	int j=0;
	int line=0;
	int row=0;
	for (int i = 0; i < D; i++) {
        for (int n = 0; n <D ; n++) {
        line=j/D;
        row=j%D;
            matrix[line][row] = j;
           j++;
        }
    }
	
	return matrix;
}
public static void printgrid(int [][] matrix) {
	for (int i = 0; i < matrix.length; i++) {
	    for (int j = 0; j < matrix[i].length; j++) {
	        System.out.print(matrix[i][j] + " ");
	    }
	    System.out.println();
	}
}
public static void findneigh(PrintWriter writer,int D,int j,int [][] matrix,double e,int tline,int trow) throws IOException {
double distance;

 
for (int i = 0; i < matrix.length; i++) {
    for (int n = 0; n < matrix[i].length; n++) {
     distance=Math.sqrt((n - trow) * (n - trow) + (i - tline) * (i - tline));	
     System.out.print(distance);
     System.out.println();
     System.out.println("tline:"+tline);
     System.out.println("trow:"+trow);
     if(distance<=e && distance!=0) {
    	 System.out.println("MPIKA");
    	 writer.write(+matrix[tline][trow]+" "+matrix[i][n]+" "+-50.0+"                                    "+'\n');  
    	 
    	
    	 
     }
    }
    
    
    }
     j++;
     tline=j/D;
     trow=j%D;
     
  if(j<(D*D)) {
    findneigh(writer,D,j,matrix,e,tline,trow);
    
    }
  else {
	  writer.close();
	  return;
  }
   

}
public static void finalfuc(int D,double r) throws IOException {
	if(D>7) {
		D=7;
	}
	int[][]m=makegrid(D);
	PrintWriter writer ;
	
	writer=opentxt();
	 findneigh(writer,D,0,m,r,0,0);
	
		
		
	
}
public static PrintWriter opentxt() throws IOException {
	FileWriter file = new FileWriter("topology.txt");
	PrintWriter output = new PrintWriter(file);
	
	return output;
}
	public static void main(String[] args) {
		try {
			finalfuc(7,1.5);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
	}
}
