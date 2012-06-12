#Serimi Functionalities.
#Author: Samur Araujo
#Date: 10 April 2011.
#License: SERIMI is distributed under the LGPL[http://www.gnu.org/licenses/lgpl.html] license.
require  File.dirname(__FILE__)+'/./solver.rb'
require  File.dirname(__FILE__)+'/./serimi_module.rb'
require  File.dirname(__FILE__)+'/../datamodel/datasource.rb'

$filter=true
$filter_threshold=0.7

class Serimi < Solver
  include Serimi_Module
  include DataSourceModule
  def initialize ()
    $number_homonyms=0
    $list_number_homonyms=[]
    $origin_subjects=[]
  end

  #####################################################################################
  #Converts the rdf data to svm records.
  #it return an array containing a array of svm records for each group of rdf data
  #####################################################################################
  def class_disambiguation(rdfdata,transitive)
    puts "RDF to SVM WITH META PROPERTIES ..."
    number_homonyms=[]
    max=nil
    min=nil
    svmmodelbygroup=[]
    ftotal = 0
    max_featuresbygroup=[]
    min_featuresbygroup=[]
    global_maximum=0

    #    puts "DATA DEBUG 1"
    #    puts  rdfdata[0][0]
    puts "############# RESTRICTED INVERSE FUNCTIONAL PROPERTIES"
    # puts $textp
    ifp = restricted_IFP(rdfdata) + $textp  + propertyoverflow(rdfdata)
    ifp.uniq!
    # puts ifp
    ifp.map!{|x| getCode(x.to_s.hash.abs)}

    groups_counter=[]
    count=-1
    pivot = nil # the smallest ambiguous set

    rdfdata.each{|group|
      count=count+1
      ########################  All Predicates  ##########################
      # puts "Encoding group ..."
      #puts group.uniq.map{|s,p,o| s.to_s + " " + p.to_s + " " + o.to_s}
      new_group = group.uniq.map{|s,p,o| [getCode(s.to_s.hash.abs),getCode(p.to_s.hash.abs),getCode(o.to_s.hash.abs),o.instance_of?(RDFS::Resource)  ]  }.compact
      # new_group = group.uniq.map{|s,p,o| [ (s.to_s ), (p.to_s ), (o.to_s),o.instance_of?(RDFS::Resource) ]  }.compact
      # puts "Selecting items of measurement ..."
      predicate_counter  = new_group.map{|s,p| p   }.compact
      datatype_objects = new_group.map{|s,p,o,t| o if !t and !ifp.include?(p) }.compact
      object_properties = new_group.map{|s,p,o,t| o if t and !ifp.include?(p) }.compact
      tuple_counter = new_group.map{|s,p,o,t| p.to_s + " " + o.to_s if !ifp.include?(p)   }.compact
      #tuple_counter = new_group.map{|s,p,o,t| p.to_s + " " + o.to_s if !ifp.include?(p) &&  discriminative_predicates.include?(p) }.compact

      # puts "Grouping subjects ..."
      subjects = new_group.map{|s,p,o,t| s}.uniq
      groupedsubject =  subjects.map{|x| new_group.find_all{|s,p,o,t| s==x}}
      groups_counter << [groupedsubject,predicate_counter,datatype_objects,object_properties,tuple_counter]
    }

    puts "Buiding Model ..."
    #####################################################################
    groups_counter_idx = -1
    groups_counter.each{|gs, group_predicates, group_datatype, group_objects, group_tuple|
      groups_counter_idx = groups_counter_idx + 1
      ################ GLOBAL PREDICATES AND OBJECTS ##############
      lines=[]
      max=nil
      count=count+1
      puts "GROUP############## - " + groups_counter_idx.to_s
      puts gs.size
      number_homonyms << gs.size
      gs.each{|subject|
        predicates = subject.map{|s,p| p }.compact
        datatype_objects = subject.map{|s,p,o,t| o if !t and !ifp.include?(p) }.compact
        object_properties = subject.map{|s,p,o,t| o if t and !ifp.include?(p) }.compact
        tuple_counter = subject.map{|s,p,o| p.to_s + " " + o.to_s if !ifp.include?(p)   }.compact
        # tuple_counter = subject.map{|s,p,o| p.to_s + " " + o.to_s if !ifp.include?(p) &&   discriminative_predicates.include?(p) }.compact

        features = []
        sim1 = 0
        sim2 = 0
        sim3 = 0
        sim4 = 0
        counter1 = -1
        # puts "SUBJECT"
        puts subject[0][0]
        #        puts tuple_counter
        ############################ Resource Vs. Origin Pivot
        if groups_counter_idx <  $origin_subjects.size
          # puts "ORIGIN SIZE "
          # puts $origin_subjects.size
          # puts   $origin_subjects[groups_counter_idx].size

          origin_s = $origin_subjects[groups_counter_idx].map{|p,o| [ getCode(p.to_s.hash.abs),getCode(o.to_s.hash.abs),o.instance_of?(RDFS::Resource) ]  }.compact
          # origin_s = $origin_subjects[groups_counter_idx].map{|p,o| [ (p.to_s ), (o.to_s),o.instance_of?(RDFS::Resource) ]  }.compact
          origin_predicates = origin_s.map{|p,o| p}.compact
          origin_datatype_objects = origin_s.map{|p,o,t| o if !t   }.compact
          origin_object_properties = origin_s.map{|p,o,t| o if t  }.compact
          origin_tuple_counter = origin_s.map{|p,o| p.to_s + " " + o.to_s    }.compact

        groups_counter.each{|gs,group_predicates,group_datatype, group_objects, group_tuple|
        sim1 = sim1 + hm(origin_predicates,predicates, gs.size.to_f)
        sim2 = sim2 + hm(origin_datatype_objects, datatype_objects, gs.size.to_f)
        sim3 = sim3 + hm(origin_object_properties, object_properties, gs.size.to_f)
        sim4 = sim4 + hm(origin_tuple_counter, tuple_counter, gs.size.to_f)
        }
        end
        # puts "PIVOT SIMILARITY"
        # puts sim1
        # puts sim2
        # puts sim3
        # puts sim4
        ############################ Resource Vs. Pseudo-Homonyms
        groups_counter.each{|gs,group_predicates,group_datatype, group_objects, group_tuple|
          counter1 = counter1 + 1
          next if groups_counter_idx == counter1
          sim1 = sim1 + hm(group_predicates,predicates, gs.size.to_f)
          sim2 = sim2 + hm(group_datatype, datatype_objects, gs.size.to_f)
          sim3 = sim3 + hm(group_objects, object_properties, gs.size.to_f)
          sim4 = sim4 + hm(group_tuple, tuple_counter, gs.size.to_f)
        }
        # puts "SIMILARITY"
        # puts sim1
        # puts sim2
        # puts sim3
        # puts sim4
        #        features << sim1
        #        features << sim2
        #        features << sim3
        #        features << sim4
        features << (sim1 + sim2 + sim3 + sim4 ).abs

        lines << features
        max = Array.new(features) if max == nil
        max.each_index{|idx| max[idx] = features[idx] if max[idx] < features[idx]}
      }
      max.each {|gg| global_maximum = gg if global_maximum < gg}
      max_featuresbygroup << max
      svmmodelbygroup <<  lines
      #      lines.each{|ss| puts ss.join (" ") }
      puts "END GROUP ###"
    }
    #    put "####### Maximum Absolute"
    #    max_featuresbygroup.map{|v| }
    puts "########### Normalizing Features"
    idx=-1
    svmmodelbygroup.map!{|g|
      idx=idx+1
      subidx = -1
      g.map!{|f|
        subidx = subidx+1
        line = ""
        f.each_index{|i|
          v =  f[i]
          if max_featuresbygroup[idx][i] != 0
            v = f[i] / global_maximum

            # v = f[i] / max_featuresbygroup[idx][i]

            if    f[i] ==  global_maximum
              # add_pivot(rdfdata[idx], @searchedlabels[idx] ,subidx) if $usepivot
              add_pivot(rdfdata[idx], nil ,subidx) if $usepivot
            end
          end
          line = line + "#{i+1}:#{v} " if !v.nan?
        }
        line
      }
    }
    # puts "THRESHOLD USED"
    # # change this if more than one feature is used.
    # $threshold_global = (max_featuresbygroup.flatten.sum.to_f/ max_featuresbygroup.size.to_f) / global_maximum
    # if $threshold_global > 0.90
    # $threshold_global = max_featuresbygroup.flatten.min
    # end
    puts $threshold_global
    #    svmmodelbygroup.each{|g| puts "GROUP ########"
    #          puts g
    #          puts "############3"
    #        }
    puts "NUMBER OF GROUPS"
    puts svmmodelbygroup.size
    puts "NUMBER OF ELEMENTS BY GROUPS 0"
    puts svmmodelbygroup[0].size if svmmodelbygroup.size > 0
    puts "NUMBER OF HOMONYMS"
    number_homonyms.each{|v | $number_homonyms = $number_homonyms + v}
    $list_number_homonyms = $list_number_homonyms + number_homonyms
    puts number_homonyms.sort.join("\t")
    puts number_homonyms.join("\t")

    return svmmodelbygroup
  end

  #####################################################################################################
  def solve(data,subjects)
    RDFS::Resource.reset_cache()

    puts "SOLVER PROCESSING #{data.size} SETS"
    $textp = get_text_properties([data])
    $selecteds=[]

    solutionset = []
    #REMOVE empty candidate sets from the list
    remove_idx = []
    data.each_index{|x|
    #            puts "############ 111"
    #             puts subjects[x]
    #            puts data[x]
    #            puts "############ 222"
      remove_idx << x if data[x].size == 0
    }
    remove_idx.reverse.each{|x|
    # @searchedlabels.delete_at(x)
      subjects.delete_at(x)
      data.delete_at(x)
    }

    puts "**************************** BUILDING SAMPLE"
    puts data.size
    return "NOT ENOUGHT SET DATA FOR CLASS  DISAMBIGUATION" if data.size < 2
    puts "*************************** PIVOT SIZE"
    puts $pivot.map{|x| x.map{|s,p| s}.uniq}
    pivot_size = $pivot.size
   #log all candidates
    # subjects.each_index{|idx|
      # data[idx].map{|s,p,o| s}.uniq.each{|i|
        # $log_candidates.write(subjects[idx].to_s.gsub(/[<>]/,"") + "=" + i.to_s.gsub(/[<>]/,"") + "\n" )
      # }
    # }

    # subjects.each{|s|
      # $log_subjects.write(s.to_s.gsub("<","").gsub(">",""))
      # $log_subjects.write("\n")
    # }
    results = union_query(subjects, $session[:origin])
    $origin_subjects = subjects.map{|x|
      results.find_all{|s,p,o| s.to_s==x.to_s}
    }

    # @searchedlabels = @searchedlabels + $pivot_labels

    svmbygroup = class_disambiguation(data + $pivot, [])

    # puts "SVM GROUP AFTER PROCESSING"
    # puts svmbygroup.size
    svmbygroup = svmbygroup[0..(svmbygroup.size - pivot_size - 1 )] if pivot_size > 0
    annotated =[]

    ############## PRINT RESULTS OF MEASURES
    svmbygroup.each{|g| puts "######"
      puts g
    }

    puts "MODEL DONE"
    puts svmbygroup.size
    puts subjects.size
    idx = -1

    puts "OUTPUT"
    puts $output

    $output =  File.open($output, 'a') if $output.class == String
    f=$output
    all_values = []
    maximus=[]
    svmbygroup.each{|svm|
      svm.map!{|x| x[(x.index(":") + 1)..x.size].to_f}
      maximus << svm.max
      all_values = all_values + svm
    }
    mean_maximus=mean(maximus)
    puts "MEAN OF MAXIMUS"
    puts mean_maximus
    all_values = all_values + [1.0] if !all_values.include?(1.0)
    global_mean_deviation = mean_and_standard_deviation(all_values)
    puts "MEAN / DEVIATION"
    puts global_mean_deviation
    outliers_threshold = [ (global_mean_deviation[0]  - global_mean_deviation[1]), global_mean_deviation[1]].max
    # outliers_threshold =  (global_mean_deviation[0]  - global_mean_deviation[1])
    puts "OUTLIER THRESHOLD"
    puts outliers_threshold

    svmbygroup.each{|svm|
      idx=idx+1
      # puts idx

      groupedsubjects = data[idx].map{|s,p,o| s}.uniq
      ########################### Calculates the threshold
      if $topk == 0
        mean_stdev =  mean_and_standard_deviation(svm)

        final_threshold = mean_stdev[0]

        if mean_stdev[1] > 0.1 and svm.max >= mean_maximus
          final_threshold = mean([svm.max,mean_maximus])
        end
        if global_mean_deviation[1] > 0.013 # I change this parameter for the new serimi at 20 may 2012. It does not cut the outliers before. Because the data was to large and too many positives
          # if global_mean_deviation[1] > 0.13
          final_threshold = [final_threshold , outliers_threshold].max
        end

        final_threshold = 0.99 if final_threshold == 1
        final_threshold = final_threshold + 0.01 if outliers_threshold == final_threshold
        final_threshold = mean_and_standard_deviation(svm.map{|v| v if v >=0.1}.compact)[0] if final_threshold < 0.1 and svm.max >= 0.1
      else
        puts "TOP-K USED"
        final_threshold = svm.sort{|a,b| b <=> a}[$topk-1]
      end

      puts "FINAL THRESHOLD - " + idx.to_s
      puts final_threshold

      ##################################################

      svm.each_index{|i|
        line = svm[i]
        puts "SCORE"
        puts line
        final_threshold= $rdsthreshold if $rdsthreshold != nil
        if line >= final_threshold
          $selecteds << groupedsubjects[i]
          solutionset << groupedsubjects[i]
          if $format == "txt"
            f.write(subjects[idx].to_s.gsub(/[<>]/,"") + "=" + groupedsubjects[i].to_s.gsub(/[<>]/,"") + "\n" )

          else
            f.write(subjects[idx].to_s + " <http://www.w3.org/2002/07/owl#sameAs> " + groupedsubjects[i].to_s + ".\n" )
          end
        end
      }

    }
    #clean the hashcode
    @counter=0
    @codes=Hash.new
    return solutionset
  end

  ####################### PIVOTING
  def add_pivot(b,keywords,subidx )
    return if $pivot.size > 10
    spivot = b.map{|s,p| s}.uniq[subidx]

    if  !$pivot_subjects.include?(spivot)
      puts "PIVOT FOUND"
      puts spivot
      $pivot << b.find_all{|s,p,o | s==spivot}
      # puts $pivot
      # exit

      # $pivot_labels << keywords
      $pivot_subjects << spivot
      if $pivot.size > 10
      $pivot.delete_at(0)
      # $pivot_labels.delete_at(0)
      $pivot_subjects.delete_at(0)
      end
    end
  end

  def hm(x,y,c)
    #    x.uniq!
    #    y.uniq!
    return 0.0 if ((x&y).size.to_f) == 0
    sim = (1/(c)**2)*tversky(x,y,0,betha2(x,y))
  # sim = (1/(c)**2)*ratio(x,y,betha2(x,y),betha2(x,y))
  # sim = (1/(c)**2)*jaccard(x,y)
  # sim = (1/(c)**2)*dice(x,y)
  #    sim = (1/(1)**1) * ratio(x,y,0,0)
  end

  def jaccard(x,y)
    return 1.0 if x.size ==0 and y.size ==0
    (((x&y).size.to_f))/(((x+y).uniq.size.to_f))
  end

  def dice(x,y)
    ((2*(x&y).size.to_f))/((x).size.to_f+(y).size.to_f)
  end

  def betha(x,y)
    1 / (1 + ((x&y).size.to_f))
  end

  def betha2(x,y)
    1 /  (((x+y).size.to_f))
  end

  def tversky(x,y,alpha,betha)
    #   (((x&y).size.to_f) )/ (((x&y).size.to_f) + (alpha.to_f*(x-y).size.to_f) + (betha.to_f*(y-x).size.to_f))
    (((x&y).size.to_f) - (alpha.to_f*(x-y).uniq.size.to_f) - (betha.to_f*(y-x).uniq.size.to_f))
  end

  def ratiotversky(x,y)
    a = betha2(x,y)
    ratio(x,y,a,a)
  end

  def ratio(x,y,alpha,betha)
    (((x&y).size.to_f) ) / (((x&y).size.to_f) + (alpha.to_f*(x-y).size.to_f) + (betha.to_f*(y-x).size.to_f))
  end

  ###################################################################################
  def propertyoverflow(rdfdata)
    data = Array.new(rdfdata)
    triples=[]

    data.each{|group|
      triples = triples + group
    }
    triples.uniq!
    triples.compact!
    triples.map!{|s,p| [s,p]}
    b=Hash.new(0)
    ifp=[]
    triples.each do |v|
    b[v] += 1
    end
    puts "PROPERTY OVERFLOW THRESHOLD"
    mean_deviation = mean_and_standard_deviation(b.values)
    puts "MEAN / DEVIATION"
    puts mean_deviation
    threshold =  [mean_deviation[0], mean_deviation[1]].max

    puts threshold
    b.each do |k, v|
      ifp << k[1] if v > threshold  and  threshold > 5
    end
    ifp.uniq!
    puts "OVERFLOW PROPERTY"

    puts ifp
    puts "##################"
    ifp
  end

  #####################################################################################################
  ################ END  FEATURES ###################
  def restricted_IFP(rdfdata,noflat=true)
    puts "Computing the IFP ... "
    data = Array.new(rdfdata)
    triples=[]
    if noflat
      data.each{|group|
        triples = triples + group
      } else
    triples = rdfdata
    end
    triples.uniq!
    triples.compact!
    ifp=[]

    triples = triples.sort{|a,b| a[1] <=> b[1] }
    current=nil
    ob=[]
    triples.each{|s,p,o|
      if current == nil
      current = p
      ob << o
      next
      end
      if current == p
      ob << o
      else
      ifp << current if ob.size == ob.uniq.size
      current=p
      ob = []
      ob << o
      end
    }
    ifp << current if ob.size == ob.uniq.size
    return ifp.uniq
  end

  def all_predicates(rdfdata)
    data = Array.new(rdfdata)
    triples=[]
    data.each{|group|
      triples = triples + group
    }
    triples.uniq!
    return triples.map{|s,p,o,| p.to_s}.uniq
  end

end

