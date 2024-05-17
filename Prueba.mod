/*********************************************
 * OPL 22.1.1.0 Model
 * Author: julian
 * Creation Date: May 9, 2024 at 8:58:31 PM
 *********************************************/
 //Parameters
string outFile=...;
string fileName=...;
int j=...;
int m=4;
{int} Jobs=asSet(1..j);//Jobs
range rangef=0..j+1;
int n[Jobs]=...;//Number of operations for each job without including the last LU
int nj[Jobs]; //Number of operations for each job including the dummy operation LU
int nTemp=...;
int nTemp2=...;

range DJobs=0..(j+1); //Dummy Jobs
int nd[DJobs];//Number of dummy operations for each dummy job
int ndnd[DJobs];



execute{
	for(var h in rangef){
	  if (h==0){
	    nd[h]=m;
	    ndnd[h]=m;
	  }
	  if (h==j+1){
	   	nd[h]=m;
	   	ndnd[h]=m;
	  }
	  if(h>=1){
	    if(h<=j){ 
	  		nd[h]=n[h]+2;
	  		ndnd[h]=n[h]+1;
	  	}
	  }
	}
	for (var g in Jobs){
	  nj[g]=n[g]+1;
	}
}

range Ops=1..max(j in Jobs)nj[j];//Operations
range DOps=1..max(j in DJobs)nd[j];//Dummy Operations

{int} ROps[j in Jobs]=asSet(1..n[j]);//Range of operations without dummy
{int} ROpsWD[j in Jobs]=asSet(1..nj[j]);//Range for operations included dummy nj+1
{int} RDOps[j in DJobs]=asSet(1..ndnd[j]);//Range for operations without dummy
{int} RDOpsWD[j in DJobs]=asSet(1..nd[j]);//Range for operations

//Parameters
int P[Jobs][Ops];//Processing time 
int t[Jobs][Ops][Jobs][Ops];//Transport time

float DD[Jobs]=...;//Due date of jobs
int A = ...;//AGVs available
int LN = 1000000; 
int Temp[1..nTemp]=...;//Storage Processing time dta
int Temp2[1..nTemp2]=...;//Storage transport data
int tt=card(DJobs)-1;

execute {
  var counter=0;
  writeln("nj ",nj);
  writeln("ndnd ",ndnd)
  writeln("Jobs: ",Jobs);
  writeln("Ops: ",Ops);
  writeln("DJobs: ",DJobs);
  writeln("DOps: ",DOps);
  for(j in Jobs){
   for(var i in ROpsWD[j]){
     for (var k in Jobs){
       for (var l in ROpsWD[k]){
         counter=counter+1;
         t[j][i][k][l]=Temp2[counter];
       };
     };
   	};
   };
   counter=0;
   for (j in Jobs){
     for(i in ROpsWD[j]){
       counter=counter+1;
       P[j][i]=Temp[counter];
       };
   };
};


// Decision variables
dvar boolean w[DOps][DJobs][DOps][DJobs];//w[i,j,k,l]
dvar boolean x[Ops][Jobs][Ops][Jobs];//x[i,j,k,l]
dvar boolean u[Ops][Jobs];
dvar boolean z[Ops][Jobs];

// Auxiliary variables
dvar float+ TD[Jobs];
dvar float+ ET;
dvar float+ c[Ops][Jobs];
dvar float+ v[Ops][Jobs];

// Objective function
minimize sum(j in Jobs) TD[j];

// Constraints
subject to {

    r03: forall(l in DJobs:l!=0) forall(k in RDOps[l]) 
            sum(i in RDOps[l]:i < k) w[i][l][k][l] + sum(j in Jobs: j!=l)sum(i in RDOps[j]) w[i][j][k][l] + sum(i in RDOps[1])w[i][0][k][l] == 1; // (3)
    r04: forall(l in DJobs:l!=tt) forall(k in RDOps[l])     
            sum(i in RDOps[l]:i > k) w[k][l][i][l] + sum(j in Jobs: j!=l)sum(i in RDOps[j]) w[k][l][i][j] + sum(i in RDOps[tt])w[k][l][i][tt] == 1; // (4)
	r05: sum(j in Jobs)sum(i in ROpsWD[j]) z[i][j] == sum(j in Jobs)sum(i in ROpsWD[j]) u[i][j]; // (5)
	r06: sum(j in Jobs) sum(i in ROpsWD[j]) u[i][j] <= A; // (6)
	r07: forall(l in Jobs)forall(k in ROpsWD[l]) u[k][l] + sum(i in ROpsWD[l]:i < k) x[i][l][k][l] + sum(j in Jobs: j!=l)sum(i in ROpsWD[j]) x[i][j][k][l] == 1; // (7)
	r08: forall(l in Jobs)forall(k in ROpsWD[l]) z[k][l] + sum(i in ROpsWD[l]:i > k) x[k][l][i][l] + sum(j in Jobs: j!=l)sum(i in ROpsWD[j]) x[k][l][i][j] == 1; // (8)
	r09: forall(l in Jobs) forall(k in ROpsWD[l]) c[k][l] - v[k][l] - P[l][k] >= 0; // (9)
	r10: forall(j in Jobs) forall(l in Jobs) forall(i in ROps[j]) forall(k in ROps[l])
	        if (j == l && k > i){c[k][l] - c[i][j] - P[l][k] >= LN * (w[i][j][k][l] - 1);}// (10)
	r11: forall(l in Jobs)forall(k in ROpsWD[l]: k!=1) v[k][l] - c[k-1][l] - t[l][k-1][l][k] >= 0; // (11)
	r12: forall(l in Jobs) v[2][l] - t[l][1][l][2] >= 0; // (12)
    r13: forall(j in Jobs) forall(l in Jobs) forall(i in ROpsWD[l]) forall(k in ROpsWD[l]: k!=1)
      	  if (j == l && k > i){ v[k][l] - v[i][j] - t[j][i][l][k-1] - t[l][k-1][j][i] >= LN * (x[i][j][k][l] - 1);} // (13)      
	r14: forall(j in Jobs) forall(l in Jobs) forall(i in ROpsWD[j])        
            if (j != l){v[2][l] - v[i][j] - t[j][i][l][1] - t[j][1][l][2] >= LN * (x[i][j][2][l] - 1);}// (14)
	r01: forall(l in Jobs) ET>=c[nj[l]][l];
    r02: forall(l in Jobs) TD[l] >= c[nj[l]][l] - DD[l];
}

