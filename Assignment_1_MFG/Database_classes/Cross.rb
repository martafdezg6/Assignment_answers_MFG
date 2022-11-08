#!/usr/bin/env ruby
# This assignment was made in collaboration with Ana Karina Ballesteros Gómez, Mariam El Akal Chaji and Ángela Gómez Sacristán.

class Cross
  # We define the attributes.
  attr_accessor :parent1
  attr_accessor :parent2
  attr_accessor :f2_w
  attr_accessor :f2_p1
  attr_accessor :f2_p2
  attr_accessor :f2_p1p2

  # We create a variables to contain the database
  @@CrossDatabase = {}
  
  # We set the initial values for the Cross Object
  def initialize (thisparent1, thisparent2, thisf2_w, thisf2_p1, thisf2_p2, thisf2_p1p2) 
      @parent1 = thisparent1
      @parent2 = thisparent2
      @f2_w = thisf2_w
      @f2_p1 = thisf2_p1
      @f2_p2 = thisf2_p2
      @f2_p1p2 = thisf2_p1p2
  end
  
  # Function to read the file and save information into database variable.
  def self.file_cross (filename)
    file = CSV.read(filename, headers: true, col_sep: "\t")
    i = 0
    file.each do |row|
      @@CrossDatabase[i] = Cross.new(row[0], row[1], row[2], row[3], row[4], row[5])
      i = i+1
    end 
    return @@CrossDatabase
  end
  
  
  # ChisQ function that analyses the linkage between the different genes
  # This function uses the database, the dictionary with the hash 
  #(seed_stock => gene_id) and the dictionary2 with the hash (gene_id => gene_name).
  def self.chisq (data, dictionary, dictionary2)
    # Variables in which we accumulate the analysis info
    @Final_report = []
    @linked_info = []

    # For each pair of genes we calculate the ChisQ according to function (O-E)²/E
    (0..4).each do |n|
      total_individuals = data[n].f2_w.to_f + data[n].f2_p1.to_f + data[n].f2_p2.to_f + data[n].f2_p1p2.to_f
      chisQ = ((data[n].f2_w.to_f - (total_individuals*9/16))**2)/(total_individuals*9/16) + ((data[n].f2_p1.to_f - (total_individuals*3/16))**2)/(total_individuals*3/16) + ((data[n].f2_p2.to_f - (total_individuals*3/16))**2)/(total_individuals*3/16) + ((data[n].f2_p1p2.to_f - (total_individuals*1/16))**2)/(total_individuals*1/16)

      # If chisQ is higher than 7.815, p-value = 0.05 and it is considered that the two genes are linked
      # We use dictionaries to relate stock id with gene name and save it into the Final report
      if chisQ > 7.815
        s=0
        var1  = dictionary["#{data[n].parent1}"]
        var2 = dictionary2["#{var1}"]
        var3  = dictionary["#{data[n].parent2}"]
        var4 = dictionary2["#{var3}"]
        puts "Recording: #{var2} is genetically linked to #{var4} with chisquare score #{chisQ}"
        @Final_report = @Final_report.append("#{var2} is linked to #{var4}")
        @Final_report = @Final_report.append("#{var4} is linked to #{var2}")
        @linked_info[s] =  [var2, var4, chisQ]
        s = s+1
      end
    end
    puts
    puts
    puts "Final report:"
    puts
    puts @Final_report
    puts
    puts
    puts '-------------------'
    return @linked_info
end 
end 
