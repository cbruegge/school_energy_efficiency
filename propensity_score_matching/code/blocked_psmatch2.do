capture program drop blocked_psmatch2
program define blocked_psmatch2
	syntax, treatvar(string) ///
			matchvars(string) ///
			balancevars(string) ///
			groupvar(string) ///
			psmatch_options(string)


			qui foreach var of local balancevars {
			
			   	cap drop match_`var'
			   	cap drop diff_`var' 
			
			   	gen match_`var' = .
			   	gen diff_`var' = .
			
			}
			
			
			levels `groupvar' if `treatvar' ~= ., local(groups)
			foreach group of local groups {

					disp "`groupvar' == `group'"

					qui sum `treatvar' if `groupvar'==`group'

					if r(sd) > 0 {

						tempvar sortorder
						gen `sortorder' = runiform()
						sort `sortorder' 

			        	psmatch2 `treatvar' `matchvars' if `groupvar'==`group', `psmatch_options'

						* Check that we're not always using the same control
						tab `treatvar' if `groupvar'==`group'

						tab _weight if `groupvar'==`group' & _treated == 0

				        sort _id
				
				        qui foreach var of local balancevars {
				
				        	replace match_`var' = `var'[_n1] if `groupvar' == `group'
				        	replace diff_`var' = `var' - match_`var' if `groupvar' == `group'
				
				        }
	
				    } 
	
				    else {
				    	disp "There is no variation in `treatvar' in `groupvar' == `group'"
				    }
			   		
			}


end
