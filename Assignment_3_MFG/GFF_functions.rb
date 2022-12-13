#Assignment3_BioinformaticRetos
# @author Ana Karina Ballesteros Gómez, Ángela Gómez Sacristán, Mariam El Akal Chaji, Marta Fernández González, Paula Fernández Aldama

require 'rest-client'  
require 'bio'
require 'csv'

#
# Function that allows us to retrieve information in the web (by Mark Wilkinson)
#
# @param [String] url URL
# @param [String] headers headers
# @param [String] user username, default ""
# @param [String] pass password, default ""
#
# @return [String, false] the contents of the URL, or false if an exception occured
#
def fetch(url:, headers: {accept: "*/*"}, user: "", pass: "")
  response = RestClient::Request.execute({
    method: :get,
    url: url.to_s,
    user: user,
    password: pass,
    headers: headers})
  return response

  rescue RestClient::ExceptionWithResponse => e
    $stderr.puts e.inspect
    response = false
    return response  
  rescue RestClient::Exception => e
    $stderr.puts e.inspect
    response = false
    return response  
  rescue Exception => e
    $stderr.puts e.inspect
    response = false
    return response  
end 

#
# This functions reads the txt file and stores and returns the information of it into an array
#
# 
# @return [Array<Symbol>] The array of gene ID 
#
def read_file()
    @file = File.read('ArabidopsisSubNetwork_GeneList.txt').split
    #this variable stores all the gene ids of the list in an array
    return @file
end

#
# Here we are creating a function that given a array with gene ids it is going to retrieve ensembl information
# and with this we are going to obtain first the chr where is located the gene, and then the start and end position 
# in the exons where the repetition CTTCCT is in local coordinates and then in complete chr coordinates for each gene
# and strand. 
# Finally this information is added as a Bio::Feature of the Bio::Sequence object that we created. 
#
# @param file [Array<Symbol>, nil] The array of gene ID or Nil (in case of an error)
#
# @return [Hash<Symbol>] embl_hash The hash of Bio::EMBL objects for each EMBL entry and which contains the Bio::Features 

def search_CTTCCT(file)
    exon_positions = [] #array that is going to store the exon position in the local coordinates 
    exon_positions2 = [] #array that it is going to store the exon position in the complete chr coordinates
    no_match_i = [] #array that is going to store all the genes that do not have the desired repetition
  
  
    for i in file 
        res = self.fetch(url: "http://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=ensemblgenomesgene&format=embl&id=#{i}");    
        if res  # res is either the response object (RestClient::Response), or false, so you can test it with 'if'
            body = res.body  # get the "body" of the response
            record = Bio::EMBL.new(body) #embl new, Bio::EMBL object
            bioseq = record.to_biosequence #convert a database entry to a Bio::Sequence
  
            chr = bioseq.entry_id #this gives us the chr where the gene is located and we store this information
            n = 0
            bioseq.features.each do |feature| 
                next unless feature.feature == "exon" #specifing the feature that we want (exon)
                locations = feature.locations.locations
                locations.each do |location|
                    exon = bioseq.subseq(location.from, location.to) # 'subseq': exon sequence , 'from', 'to' : positions
                    next if exon == nil  #handling the cases that we have a nil response 
                    if location.strand == +1  #retrieving the location in the case of the + strand
                        reps =(Bio::Sequence::NA.new("CTTCTT")).to_re #converting the sequence into a regex and if it match we store in the array the gene, the start and end position and the strand
                        if exon.match(reps)
                            exon_position = exon.index(reps)
                            start_pos = exon_position + location.from  
                            exon_positions << [i, start_pos , start_pos +5 , '+']
                            n = n+1
                        end
                    else  #here we calculate the position in the case of - strand
                        reps =(Bio::Sequence::NA.new("CTTCTT")).complement.to_re
                        if exon.match(reps)
                            exon_position = exon.index(reps)
                            start_pos = exon_position + location.from
                            exon_positions << [i, start_pos, start_pos +5, '-']
                            n = n+1
                        end
                    end
                end
            end
  
            if (n == 0) #store those genes that do not match with the desired sequence
                no_match_i << i
            end
  
  
          #Now we are going to apply similar code but taking in count the coordinates of the gene in the whole chromosome
            bioseq.features.each do |feature| 
                next unless feature.feature == "exon"
                locations = feature.locations.locations
                locations.each do |location|
                    exon = bioseq.subseq(location.from, location.to) # 'subseq': exon sequence , 'from', 'to' : positions
                    next if exon == nil
                    if location.strand == +1
                        reps =(Bio::Sequence::NA.new("CTTCTT")).to_re
                        if exon.match(reps)
                            exon_position = exon.index(reps)
                            start_gen = (bioseq.primary_accession.split(":")[3]).to_i #this allows us to retrieve in complete chr coordinates where does the gene starts
                            start_pos = exon_position + start_gen + location.from  #now we get the real start position by adding the exon start position in the gene and where does the gene starts in the genome
                            exon_positions2 << [i, chr, start_pos , start_pos +5 , '+']
                        end
                    else
                        reps =(Bio::Sequence::NA.new("CTTCTT")).complement.to_re
                        if exon.match(reps)
                            exon_position = exon.index(reps)
                            start_gen = (bioseq.primary_accession.split(":")[3]).to_i
                            start_pos = exon_position + start_gen + location.from #this gives us where the gene starts
                            exon_positions2 << [i, chr, start_pos, start_pos +5, '-'] #now we get the real start position by adding the exon start position in the gene and where does the gene starts in the genome
                        end
                    end
                end
            end      
  
  
        else
          puts "the Web call failed - see STDERR for details..." 
        end
    end

    # here we are keeping with the unrepeated values of the exon_postions that we obtained, also we are storing them as a Bio::Feature 
    exon_positions.uniq.each do |feature|
        position = [feature[1],feature[2]]
        ft= Bio::Feature.new('misfeatures',position) 
        ft.append(Bio::Feature::Qualifier.new('repeat_region', 'CTTCTT'))
        ft.append(Bio::Feature::Qualifier.new('Gene_id', feature[0]))
        ft.append(Bio::Feature::Qualifier.new('note', 'found by repeatfinder 2.0'))
        ft.append(Bio::Feature::Qualifier.new('strand', feature[3]))
        bioseq.features << ft
    end

    exon_positions2.uniq.each do |feature|
      position = [feature[2],feature[3]]
      ft= Bio::Feature.new('misCfeatures',position) 
      ft.append(Bio::Feature::Qualifier.new('repeat_region', 'CTTCTT'))
      ft.append(Bio::Feature::Qualifier.new('Gene_id', feature[0]))
      ft.append(Bio::Feature::Qualifier.new('Chr', feature[1]))
      ft.append(Bio::Feature::Qualifier.new('note', 'found by repeatfinder 2.0'))
      ft.append(Bio::Feature::Qualifier.new('strand', feature[4]))
      bioseq.features << ft
    end
    
    no_match_i.each do |id|
      ft= Bio::Feature.new('NoMatchfeatures','No match')
      ft.append(Bio::Feature::Qualifier.new('Gene_id', id)) 
      bioseq.features << ft
    end
    return bioseq
  end

#This function writes the 3 output files 
#
# @param bioseq [Hash<Symbol>] The Bio::Sequence objects that contains the features that we added
#

def write_files(bioseq)
  File.open("GFF3_report_reex.gff", "w") { |f| f.write "" }
  File.open("GFF3_report_reex.gff", "a") { |f| f.write "##gff-version 3\n" }
  File.open("GFF3_report.gff", "w") { |f| f.write "" }
  File.open("GFF3_report.gff", "a") { |f| f.write "##gff-version 3\n" }
  File.open("Report_file.txt", "w") { |f| f.write "" }
  File.open("Report_file.txt", "a") { |f| f.write "\t\t\t\t\tREPORT\n######################################################\n" }
  File.open("Report_file.txt", "a") { |f| f.write "Genes that do NOT have exons with the CTTCTT repeat:\n\n" }
    bioseq.features.each do |entrada|
      if entrada.feature == "misCfeatures"
        File.open("GFF3_report_reex.gff", "a") { |f| f.write "#{entrada.qualifiers[2].qualifier}#{entrada.qualifiers[2].value}\t.\t#{entrada.qualifiers[0].qualifier} #{entrada.qualifiers[0].value}\t#{entrada.position[0]}\t#{entrada.position[1]}\t.\t#{entrada.qualifiers[4].value}\t.\t.\n" }
      elsif entrada.feature == "misfeatures"
        File.open("GFF3_report.gff", "a") { |f| f.write "#{entrada.qualifiers[1].value}\t#{entrada.qualifiers[0].qualifier} #{entrada.qualifiers[0].value}\t#{entrada.position[0]}\t#{entrada.position[1]}\t.\t#{entrada.qualifiers[3].value}\t.\t.\n" }
      elsif entrada.feature == "NoMatchfeatures"
        File.open("Report_file.txt", "a") { |f| f.write "#{entrada.qualifiers[0].value}\n" }
      end  
    end
end
