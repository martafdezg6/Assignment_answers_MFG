#!/usr/bin/env ruby
# This assignment was made in collaboration with Ana Karina Ballesteros Gómez, Mariam El Akal Chaji and Ángela Gómez Sacristán.

require "csv"
require "date"
require './Database_classes/Genes.rb'
require './Database_classes/SeedStock.rb'
require './Database_classes/Cross.rb'

#Control of arguments 
if ARGV.length() != 4
    abort("WARNING! I expected 4 arguments, check your arguments")
end 

# We read the given Seed file and save the different objects in database. 
Seed_Database = Seed.reading_file(ARGV[1])

# Simulation of the plantation:
Seed.plantation()

#First of all we are going to design first hash
dictionary = Seed.update_hash(Seed_Database)

# We create a new dataset with the updated information and a given name
Seed.gen_new_table(ARGV[3])

# We read the given Genes file and crete the database
Genes_Database = Genes.file_gene(ARGV[0])

# We design the second hash
dictionary2 = Genes.update_hash(Genes_Database)

# Once we have done the plantation and generated the new dataset, we are going to study the  linkage of the different genes

# We read the given Cross file and create the database
Cross_Database = Cross.file_cross(ARGV[2])

# We perform linkage analysis with chi-square function
linked_info = Cross.chisq(Cross_Database, dictionary, dictionary2)

# We include the linkage information for each gene in the gene database
Genes.linkage(linked_info)


