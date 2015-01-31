capture program drop save_psmatch2_table
program define save_psmatch2_table
	syntax, balancevars(string) ///
			output_file(string)

			capture file close myfile
			file open myfile using "`output_file'", write replace	
			file write myfile "Category" _tab "Mean Diff" _tab "Standard Deviation" _tab "Min" _tab "Max" _n
			qui foreach var of local balancevars {
				local lablocal: var label `var'
				file write myfile "`var'" _tab
			
				summ diff_`var'
			
				file write myfile " " %4.1f (r(mean)) _tab
				file write myfile " " %4.1f (r(sd)) _tab
				file write myfile " " %4.1f (r(min)) _tab
				file write myfile " " %4.1f (r(max)) _n
			
			}
			file close myfile

end

