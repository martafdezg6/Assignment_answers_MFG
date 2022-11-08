#!/usr/bin/env ruby
# This assignment was made in collaboration with Ana Karina Ballesteros Gómez, Mariam El Akal Chaji and Ángela Gómez Sacristán.

class Genes
  # We define the attributes.
  attr_accessor :genes_id
  attr_accessor :gene_name
  attr_accessor :mutant_phe
  attr_accessor :linked_genes

  # We create two variables to contain the database and the hash(dictionary created with the gene id and the gene name)  

  @@GenesDatabase={}
  @@genes_id ={}

  # We set the initial values for the Genes Object
  
  def initialize (thisgenes_ID, thisgene_names, thismutants_phenotype)
    @genes_id =  thisgenes_ID
    @gene_name = thisgene_names
    @mutant_phe = thismutants_phenotype
    @@genes_id[genes_id] = thisgene_names #creating a hash
    @linked_genes = ''
    

    # We make sure the genes_id format is correct
    correct_format = /A[Tt]\d[Gg]\d\d\d\d\d/ 
    unless correct_format.match(@genes_id)
        abort("ERROR!!!: Incorrect ID format.")
    end
  end 
  
  # Function to read the file and save information into database variable.
  def self.file_gene(filename)
    
    genes_file = CSV.read(filename, col_sep: "\t", headers: true)
    
    #Have each seed in a line
    i=0
    genes_file.each do |gene|
      @@GenesDatabase[i] = Genes.new(gene[0], gene[1], gene[2])
      i = i+1
    end
    return @@GenesDatabase
  end 
  
  def self.describe(gene)
    puts "#{gene.gene_name} is linked to #{gene.linked_genes}"
  end
  
  # We  generate a dictionary with gene id and gene name
  def self.update_hash(data)
    @@genes_id.each do |data|
      data[1]
    end
  end

  # Function that adds information about linked genes to the database
  def self.linkage(linked_info)
    linked_info.each do |row|
      (0..4).each do |gene|
        if @@GenesDatabase[gene].gene_name == "#{row[0]}"
          @@GenesDatabase[gene].linked_genes = row[1], row[2]
        end
        if @@GenesDatabase[gene].gene_name == "#{row[1]}"
          @@GenesDatabase[gene].linked_genes = row[0], row[2]
        end
      end
    end
  end

  # Function that finds the gene by its ID
  def self.find_gene_by_id(id) #Find gene by ID
        @@GenesDatabase.each do |gene|
            if gene[1].genes_id == id
              return gene[1]
            end
        end
  end
end 
