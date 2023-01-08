require 'bio'

''' 
BLAST DATABASE

A function was designed in order to to guess the type of sequence 
in the fasta file: the function checks if the file contains NA 
(nucleic acid) or AA (aminoacids, that is, a protein)) sequences

'''

# @param [String] file The name of the fasta file of sequences
# @return [String] Saying if the file contains NA or AA 

def sequencetype(file) 
    flatfile=Bio::FlatFile.auto(file) #flatfile object with the input file
    firstseq=Bio::Sequence.new(flatfile.next_entry.seq) # getting the first sequence in the file
    if firstseq.guess == Bio::Sequence::NA # if the sequence is NA
      return 'nucleic acid' 
    else # if isn NA, then is AA
      return 'protein'
    end
  end

'''
BLAST TYPE 

A function was designed in order to get the blast type based on the
type of sequence obtained in the previous function.

'''

# @param [String] query_file Blast
# @param [String] db_file Database

# @return [String] Type of blast 

def blast (query_file, db_file)
    flatfile=Bio::FlatFile.auto(query_file) #flatfile object with the input file
    flatfile2=Bio::FlatFile.auto(db_file)
    firstseq=Bio::Sequence.new(flatfile.next_entry.seq) # getting the first sequence in the file
    firstseq2=Bio::Sequence.new(flatfile2.next_entry.seq)
    if firstseq.guess == Bio::Sequence::NA and firstseq2.guess == Bio::Sequence::AA
      return 'blastx'
    elsif firstseq.guess == Bio::Sequence::AA and firstseq2.guess == Bio::Sequence::NA
      return 'tblastn'
    elsif firstseq.guess == Bio::Sequence::AA and firstseq2.guess == Bio::Sequence::AA
      return 'blastp'
    elsif firstseq.guess == Bio::Sequence::NA and firstseq2.guess == Bio::Sequence::NA
      return 'blastn'
    end
  end

'''
DATABASE 

A function was defined in order to save the databases of both organisms

'''

# @param [String] file Fasta file
# @param [String] blast Type of blast

def database_for_blast (file, blast)
    newname = file.split('.')[0]
    if blast == 'blastx'
      `makeblastdb -in #{file} -dbtype 'prot' -out #{newname}`
    elsif blast == 'tblastn'
      `makeblastdb -in #{file} -dbtype 'nucl' -out #{newname}`
    end
  end

'''
FILE SIZE
'''

# @param [String] file The name of the file
# @return [Integer] size The size of the file

def file_size(file)
    flatfile=Bio::FlatFile.auto(file) #flatfile object with the input file
    n = 0
    flatfile.each do |o|
      n = n+1
    end
    size = n
    return size
end

'''
BLAST (1/3)

Different functions were designed in order to perform the blast:

1. The first function performs the blast between the two species taking into account the 
query_file and the db_file, we will put one database  type or another, the first function 
has also as an argument the file  size in order to let the user know the progress. 

'''

# @param [String] fastatype The type of blast made
# @param [String] filename1 The filename of the file for species 1
# @param [String] filename2 The filename of the file for species 2
# @param [Integer] size The size of the file  

# @return [Array<Symbol>] list Array with the ortologues found 

def search_orthologues(fastatype, filename1, filename2, size)

    threshold = 10**-6
    list = []
    fact = Bio::Blast.local(fastatype,"#{File.dirname(filename1)}/#{File.basename(filename1,".fa")}")
    flatfile=Bio::FlatFile.auto(filename2) #flatfile object with the input file
    flatfile.rewind 
    # iterating over each entry in file_1 --> entry = query 
    n = 1
    flatfile.each do |query|
        i = n/(size).to_f
        print "#{(i*100).round(2)}%\r" #tb se saca como query.definition[0,11] 
        $stdout.flush
        rep = fact.query(query)
        if rep.hits[0] != nil and rep.hits[0].evalue <= threshold
            list.append([query.entry_id, rep.hits[0].definition.split("|")[0]])
        end
        n = n+1
    end
    return list
end

'''
BLAST (2/3)

2. Looks for the hits obtained in the first blast, saved in list and 
saves them in a new list named candidates2.

'''

# @param [Array<Symbol>] list Array that contains the hits of the first blast 
# @return [Array<Symbol>] candidates2 Array that contains the hits looked out in the first blast 

def search_candidates(list)
    candidates = list.map {|row| row[1]}
    candidates2 = []
    i = 0
    candidates.each do |can|
        candidates2.append(candidates[i][0,11])
        i = i+1
    end 
    return candidates2
end

'''
BLAST (3/3)

3. The last function performs the reciproc blast, now the user has to take into account
the query_file and the db_file, the database type, the database size in order to let 
the user know the progress. This last function differs from the first one because it 
has the candidates argument, so it takes into account the candidates found in the first
blast. 

'''

# @params [String] fastatype The type of blast to be made
# @param [String] filename1 The filename of the file for species 1
# @param [String] filename2 The filename of the file for species 2
# @param [Integer] size The size of the file  
# @param [Array] candidates Candidates found in the first blast
# @param [Array] list Array with the ortologues found 
# @return [Array<Symbol>] ortologos Reciproc blast 

@return [Array<Symbol>] ortologos Reciproc blast 

def check_orthologues(fastatype, filename1, filename2, size, candidates, list)
    ortologos = []
    fact = Bio::Blast.local(fastatype,"#{File.dirname(filename1)}/#{File.basename(filename1,".fa")}")
    flatfile=Bio::FlatFile.auto(filename2) #flatfile object with the input file
    flatfile.rewind 
    # iterating over each entry in file_1 --> entry = query 
    n = 1
    flatfile.each do |query|
    if candidates.include?(query.entry_id)
        i = n/(size).to_f
        print "#{(i*100).round(2)}%\r"
        $stdout.flush
        index = candidates.find_index(query.entry_id)
        #puts query.entry_id #tb se saca como query.definition[0,11] 
        rep = fact.query(query)
        if rep.hits[0] != nil and list[index][0] == rep.hits[0].definition.split("|")[0]
            ortologos.append([query.entry_id, rep.hits[0].definition.split("|")[0]])
        end
    end
    n = n+1
    end
    return ortologos
end
    
'''
REPORT

This last function was created in order to obtain a report of the different orthologues.

'''
# @param [Array<Symbol>] ortologos Reciproc blast made

def write_report(ortologos)
    File.open("Report.txt", "w") { |f| f.write "" }
    File.open("Report.txt", "a") { |f| f.write "FINAL REPORT with ortologues candidates\n\n" }
        ortologos.each do |pair|
            File.open("Report.txt", "a") { |f| f.write "#{pair[0]}\t-->\t#{pair[1]}\n"}
        end
end 
