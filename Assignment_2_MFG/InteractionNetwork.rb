#Assignment2_BioinformaticRetos
#Colaborators: Ana Karina Ballesteros Gómez, Ángela Gómez Sacristán, Mariam El Akal Chaji, Marta Fernández González, Paula Fernández Aldama


require 'rest-client'  

class InteractionNetwork
  
  attr_accessor :net_num
  attr_accessor :interactor
  attr_accessor :members
  attr_accessor :goannot
  attr_accessor :keggannot
  attr_accessor :interactions
  
  ## initializing instance variables ##
  def initialize(net_num, interactor, members)
    @net_num = net_num
    @interactor = interactor
    @members = members
    @goannot = ''
    @keggannot = ''
    @interactions = ''
  
  end
  
  @@genes = {}
  @@total = {}
  @@Final_report = {}
  
  def self.store_id_files(filename)
    file = File.readlines(filename) #here we read the file and make that the output is an array
    @@genes = file.collect(&:strip).map(&:upcase) #we delete the \n that appeared after each id in the array and we store the gene id of the file in a variable
    return @@genes
  end 
  
  def self.fetch(url:, headers: {accept: "/"}, user: "", pass: "") #function for retrieving information of the web
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
    return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
  rescue RestClient::Exception => e
    $stderr.puts e.inspect
    response = false
    return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
  rescue Exception => e
    $stderr.puts e.inspect
    response = false
    return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
  end 
  
  def self.search_interactions(gene_id)
    res = InteractionNetwork.fetch(url: "http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/search/interactor/#{gene_id}?format=tab25")
    body = [] #here we are saving the body of the search that we have mande 
    interactions = [] #here we are storing the information that we are interested on about the network

    if res 
      body.append(res.body) #here we save the sultant body in the variable body
    end

    body.each do |entry|
      entry = entry.split("\n") #getting rid of the \n in the body
      entry.each do |record|
        inter = record.split("\t") #getting rid off \t in the file
        inter = inter[2], inter[3], inter[9], inter[10], inter[14].split(":") #in the body the [2] and [3] are the genes, [9] and [10] are the information about the species (taxid) and [14] contains the value of the score
        interactions.append(inter)                                            #we split the score in order to extract the value later
      end 
    end
    int_genes = []
    interactions.each do |row|
      if row[2].match(/taxid:3702/) && row[3].match(/taxid:3702/) && row[4][1].to_f > 0.5 && row[0].match(/A[Tt]\d[Gg]\d\d\d\d\d/) != row[1].match(/A[Tt]\d[Gg]\d\d\d\d\d/) 
      #here we are looking out for the interactions that feats with the features of species(arabidopsis, taxid=3702), and quality(we use a quality score of 0.5 in order to be a little demanding about the genes that we are considering for the networks), also we are keeping only with the interactions that contains genes in AGI code
        gen1 = row[0].match(/A[Tt]\d[Gg]\d\d\d\d\d/).to_s.upcase 
        gen2 = row[1].match(/A[Tt]\d[Gg]\d\d\d\d\d/).to_s.upcase
        int_genes.append(gen1, gen2)
        int_genes.delete_if{|gen| gen == gene_id.upcase} #Here we have appended the interactions that we found in psiquic to an array and delete the ones that fits with the query
      end 
    end
    return int_genes
  end 
  
  def self.get_nets_hash()   #this functions saves each one of the genes of the file as the keys of a hash (all_interactions), where the values corresponds to the genes which they interact (according to the search_interactions function)
    all_interactions = Hash.new
    @@genes.each do |gene_id|
      int_genes = InteractionNetwork.search_interactions(gene_id) 
      int_genes.each do |interacted| 
        a_i = []
        if @@genes.include?(interacted) #first we are saving just the interactions of genes that actually appears on our list (both genes are in the file txt)
          a_i.append(interacted)
        elsif !@@genes.include?(interacted) #for the contrary if the gene is not in the list we are consider the option that A interacts with X that interacts with B in which A and B are both of our list and X is an intermediary gene between them
          int_genes2 = InteractionNetwork.search_interactions(interacted)
          int_genes2.each do |interacted2|
            if @@genes.include?(interacted2) #&& interacted2 != gene_id.upcase
              a_i.append([interacted,interacted2])
            end
          end
        end

        if !a_i.empty?
          all_interactions[gene_id]=a_i
        end 
      end
    end
    return all_interactions
  end
  
  def self.fill_object(all_int)  #now we fill the object with the result of the search, that we have already saved, also we look out for the Keeg annotations and also the GO annotations
    i = 0
    all_int.each do |key, value|
      a = []
      a.append(key)
      value.each do |n|
        if n.size()==2
          a.append(n[0], n[1])
        elsif n.size()==1
          a.append(n)
        end
      end
      list = a.uniq
      @@total[i] = InteractionNetwork.new(i, key, list)
      i = i+1
    end
    
    int_list = InteractionNetwork.interactions(all_int) 
    n = 0
    @@total.each do |classe|
      kt = []
      gt = []
      classe[1].members.each do |gene_id|
        k = InteractionNetwork.kegg("#{gene_id}")
        g = InteractionNetwork.go("#{gene_id}")
        
        if k == {}
          kt.append("ID: #{gene_id} -> KeggAnnotation: No anotation found")
        else 
          kt.append("ID: #{gene_id} -> KeggAnnotation: #{k}")
        end 

        if g == {}
          gt.append("ID: #{gene_id} -> GoAnnotation: No anotation found")
        
        else 
          gt.append("ID: #{gene_id} -> GoAnnotation: #{g}")
        end 
      end
      classe[1].interactions = int_list[n]
      classe[1].keggannot = kt
      classe[1].goannot = gt
      n = n+1
    end    
    return @@total
  end
  
  def self.Show_report() #this functions writes out the final report of the program
    File.open("final_report.txt", "w") { |f| f.write "" }
    File.open("final_report.txt", "a") { |f| f.write "FINAL REPORT\n\n" }
    @@total.each do |classe|
      n = classe[1].net_num
      File.open("final_report.txt", "a") { |f| f.write "NETWORK #{n}\n------------------ \nNETWORK MEMBERS:\n#{classe[1].members}\n\nNETWORK INTERACTIONS:\n#{classe[1].interactions}\n\nGO ANNOTATIONS OF MEMBERS:\n#{classe[1].goannot}\n\nKEGGS ANNOTATIONS OF MEMBERS:\n#{classe[1].keggannot}\n\n" }
    end
  end
  
  def self.interactions(all_int)  #in this functions we stablish the relations between the genes that are part of each network
    n = 0
    all_int.each do |key, value|
      arr = []
      value.each do |gene|
        if gene.size() == 2
          arr.append("#{key} interacts with #{gene[1]} with intermediate #{gene[0]}")
        else
          arr.append("#{key} interacts with #{gene}")
        end
      end
      @@Final_report[n]=arr
      n = n+1
    end 
    return @@Final_report
  end
  
  
  def self.kegg(gene_id)  #the function that is used in the function fill_object, and which looks out for the keeg annotations
    res = InteractionNetwork.fetch(url:"http://togows.dbcls.jp/entry/uniprot/#{gene_id}/dr.json")
    data = JSON.parse(res.body)

    ###Kegg anotations retrieval
    kegg_all = data[0]['KEGG']
    kegg_id = []

    kegg_all.each do |row|
      kegg_id.append(row[0])
    end 

    for element in kegg_id
      id = element
      res1 = InteractionNetwork.fetch(url:"http://togows.org/entry/kegg-genes/#{id}.json")
      data1 = JSON.parse(res1.body)
      pathways_all = data1[0]['pathways']
    end
    return pathways_all
  end 

  def self.go(gene_id)  #the function that we have used in fil_object function in order to annotate the go terms and id
    res = InteractionNetwork.fetch(url:"http://togows.dbcls.jp/entry/uniprot/#{gene_id}/dr.json")
    data = JSON.parse(res.body)
    
    ###GO anotations retrieval
    go_all = data[0]['GO']
    go_list = Hash.new
    if !go_all.nil?
      go_all.each do |go| 
        go[1].split(":")[1] 
        if (go[1][0] == "P")
          go_list[go[0]] = go[1]
        end 
      end
    end
    return go_list
  end
  
end   