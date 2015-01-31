capture program drop matrix_to_table
program define matrix_to_table
	syntax, balancevars(string) ///
			model_names(string) ///
			output_file(string)

			local number_of_colums = wordcount("`model_names'")
			local number_of_rows = wordcount("`balancevars'")
			tokenize "`model_names'"

			capture file close myfile
			file open myfile using "`output_file'", write replace

			* Header 
			file write myfile "\begin{table}" _n
			file write myfile "\begin{tabular}{"
			forvalues col = 1/`number_of_colums' {
				if `col' == `number_of_colums' {
					file write myfile "cc}" _n
				} 
				else {
					file write myfile "c"
				}
			}
			file write myfile "\hline" _n
			file write myfile "\hline" _n

			* Column Names
			file write myfile "& " _tab
			forvalues col = 1/`number_of_colums' {
				local col_name = "``col''"
				while regexm("`col_name'","_") {
					local col_name = regexr("`col_name'","_","")
				}

				if `col' == `number_of_colums' {
					file write myfile "`col_name' \\ " _n
				} 
				else {
					file write myfile "`col_name' & " _tab
				}
			}	

			* Data
			file write myfile "\hline" _n

			tokenize "`balancevars'"

			forvalues var_num = 1/`number_of_rows' {

				local var_name = "``var_num''"
				while regexm("`var_name'","_") {
					local var_name = regexr("`var_name'","_","")
				}

				file write myfile "`var_name' & " 

				local col_counter = 0
				foreach model of local model_names {
					local col_counter = `col_counter' + 1

					if `col_counter' == `number_of_colums' {
						file write myfile %4.1f (`model'[`var_num',1]) " \\ " _n

					} 
					else {
						file write myfile %4.1f (`model'[`var_num',1]) " & "
					}
				}

				file write myfile " & "
				local col_counter = 0
				foreach model of local model_names {
					local col_counter = `col_counter' + 1

					if `col_counter' == `number_of_colums' {
						file write myfile " (" %4.1f (`model'[`var_num',2]) ") \\ " _n
					} 
					else {
						file write myfile " (" %4.1f (`model'[`var_num',2]) ") & "
					}
				}

				file write myfile " & "
				local col_counter = 0
				foreach model of local model_names {
					local col_counter = `col_counter' + 1

					if `col_counter' == `number_of_colums' {
						file write myfile " [" %4.1f (`model'[`var_num',3]) ","
						file write myfile %4.1f (`model'[`var_num',4]) "] \\ " _n
					} 
					else {
						file write myfile " [" %4.1f (`model'[`var_num',3]) ","
						file write myfile %4.1f (`model'[`var_num',4]) "] & " 
					}
				}

			}

			file write myfile "\hline" _n
			file write myfile "\hline" _n
			file write myfile "\end{tabular}" _n
			file write myfile "\end{table}" _n


			file close myfile

end

