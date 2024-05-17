/*********************************************
 * OPL 22.1.0.0 Model
 * Author: julian
 * Creation Date: May 14, 2024 at 2:24:26 PM
 *********************************************/
/*********************************************
 * OPL 22.1.1.0 Model
 * Author: julian
 * Creation Date: May 11, 2023 at 3:19:46 PM
 *********************************************/
main {
      var source = new IloOplModelSource("Prueba.mod");
      var dataFile="Data.dat";
	  
      for(var a=1;a<=5;a++)
      {
        var cplex = new IloCplex();
     	var def = new IloOplModelDefinition(source);
        var opl = new IloOplModel(def,cplex);
        
        var dataSource=new IloOplDataSource(dataFile);
        var dataElements = new IloOplDataElements();
        dataElements.add(dataSource);
        
        dataElements.fileName="EX11-1.xlsx";
        dataElements.A = a;
        
        opl.addDataSource(dataElements);
      	opl.generate();
      	
      	
		var beforeTime = new Date();
		var compTime = beforeTime.getTime();
		var ofile = new IloOplOutputFile("results_A ",a," ",opl.outFile,".csv",false);
		cplex.tilim = 3600;
   		cplex.threads = 4;
      	if (cplex.solve())
      	{
      	  	opl.postProcess();
      	  	
   
   			var objectiveValue = cplex.getObjValue();
  			var lowerBoundValue = cplex.getBestObjValue();
  			var gap = ((objectiveValue - lowerBoundValue)/Math.max(objectiveValue,Math.abs(lowerBoundValue)))*100;
  			
		   	var afterTime = new Date();
		   	compTime = (afterTime.getTime()-compTime)/1000;
		   	
		   	ofile.writeln("Data File: ", opl.outFile)
		   	ofile.writeln("Tardiness,Exit time,Computational Time(s),Optimality Gap (%),Vehicles ")
		   	ofile.writeln(objectiveValue,",",opl.ET,",",compTime,",",gap,",",opl.A);
		   	for(var i in opl.Jobs){
		   	  for(var j in opl.ROpsWD[i]){
		   	    for(var k in opl.Jobs){
		   	      for(var l in opl.ROpsWD[k]){
		   	        if(opl.x[i][j][k][l]!=0){
              				ofile.writeln("T" , j + "," , i , " after T" , l , "," , k)
              			}		   	          
		   	      	}   	      
		   	      }
		   	    }
		   	  }
		   	 for(i in opl.DJobs){
		   	  for(j in opl.RDOpsWD[i]){
		   	    for(k in opl.DJobs){
		   	      for(l in opl.DOpsWD[k]){
		   	        if(opl.w[j][i][l][k]!=0){
              				ofile.writeln("Operation ", j , " job " , i , " after Operation " , l , " job " , k)
              			}		   	          
		   	      	}   	      
		   	      }
		   	    }
		   	  }
		}
		else {
         	ofile.writeln("No feasible solution found");
      	}
      	ofile.writeln("--------------\n");
      	ofile.close();
      	
      	opl.end();
      	cplex.end();
      }
}