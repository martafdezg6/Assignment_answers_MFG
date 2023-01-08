require './Assigment4.rb'

'''
First of all, the blast type was obtained using the
blast function, after that databases were created for 
both blasts pep_1 vs TAIR_10 and viceversa.
'''
#TAIR_10 database
tblast = blast(ARGV[0], ARGV[1])
database_for_blast(ARGV[1], tblast)

#pep_1 database
tblst = blast(ARGV[1], ARGV[0])
database_for_blast(ARGV[0], tblst)

'''
After that, the size of both files was obtained using the
size function
'''
pep_size = file_size(ARGV[0])
tair_size = file_size(ARGV[1])

'''
In this step the orthologues search was performed, two blasts 
were performed tair_10 vs pep_1 and pep_1 vs tair_10. After the 
first blast the different hits were saved in a list called candidates
and the result was used to perform the reciprocal blast.
'''
puts "Performing First blast"
tair_vs_pep = search_orthologues(tblast, 'TAIR10_cds_20101214_updated_1', ARGV[0], pep_size)

blast_candidates = search_candidates(tair_vs_pep)

puts "Performing Second blast"
pep_vs_tair = check_orthologues(tblst, 'pep_1', ARGV[1], tair_size, blast_candidates, tair_vs_pep)

'''
Finally, a report was obtained. 
'''
write_report(pep_vs_tair)