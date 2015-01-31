capture program drop define_summary_stat_matrix
program define define_summary_stat_matrix
	syntax, balancevars(string) ///
			outmatrix(string)

			* Find Number of Balance Variables
			local num_balancevars = wordcount("`balancevars'")

			* Define the empty outmatrix
			matrix define `outmatrix' = J(`num_balancevars',4,0)

			* Populate the outmatrix with summary stats
			local counter = 0
			qui foreach var of local balancevars {
				local counter = `counter' + 1
			
				summ diff_`var'
				
				matrix `outmatrix'[`counter',1] = r(mean)
				matrix `outmatrix'[`counter',2] = r(sd)
				matrix `outmatrix'[`counter',3] = r(min)
				matrix `outmatrix'[`counter',4] = r(max)
			
			}


end

