columnsExist macro instructions for use.
1. Put the following line of code in your code. It must be place before the spot where you intend to use the macro.
	%include('<directory the code is stored>\columnsExist.sas');
2. Change the information between the single quotes to the location where you put the columnsExist.sas file.
3. Use in your code with the following example.
	%columnsExist(library=test, table=test1, columns=col1 col2 col3);
4. Enjoy.