module Serimi_Module
  ############## Building Class Queries ###############
  def class_queries(subjects,data,solver)
    return nil if subjects == nil || subjects.size == 1
    puts "SUBJECTS"
    puts subjects

    negatives=[]
    triples = []
    data.each{|x| triples = triples + x }

    triples.delete_if {|s,p,o|  !o.instance_of?(RDFS::Resource)}

    positives = triples.map {|s,p,o| [s,p,o] if subjects.include?(s)  }.compact
    negatives = triples - positives

    return solver.solve(positives,negatives)

  end

  ####################################################################################################
  def entropy_computation(data)
    $textp = [] if $textp == nil
    # return discriminability(data)
     $textp = [] if $textp == nil
     triples=[]
     instances=[]
     # ccc= 0
     noempty=0
     data.each{|x|
     if x.size > 0
     noempty=noempty + 1
     end
    
     if data.size ==1
     triples = triples + x.map{|s,p,o| [p,o] }
     instances = instances + x.map{|s,p,o| [s,p] }
     else
     triples = triples + x.map{|s,p,o| [p,o] }.uniq
     instances = instances + x.map{|s,p,o| [s,p] }.uniq
     end
     }

     instances_size = instances.map{|s,p| s}.uniq.size.to_f
    
     predicates = triples.map{|p,o| p if !$textp.include?(p)}.compact.uniq
     entropies = Hash.new
    
     predicates.each{|pre|
     objects = triples.find_all{|p,o| p==pre}.map{|p,o| o}
     entropy = 0
     objects.uniq.each{|o|
     entropy = entropy + entropy(objects.find_all{|r| r==o }.size.to_f/objects.size.to_f)
     }
     entropy = -1 * entropy
    
     entropy = entropy / Math.log(objects.size.to_f)
    
    entropy = entropy * (instances.find_all{|s,p| p==pre }.uniq.size.to_f/instances_size )
    
     if !entropy.nan?
     entropies[pre] = ( 1 -  entropy ).abs
     end
     }
     # puts entropies
     sorted_entropies = sort(entropies)
     puts "ENTROPIES"
     # puts entropies
     predicates = []
     entropy_threshold = 0
     sorted_entropies.each{|k,v|
     entropy_threshold = entropy_threshold + v
     }
     entropy_threshold = entropy_threshold.to_f / entropies.size.to_f
    all_predicates=[]
     sorted_entropies.each{|k,v|
     puts k
     puts v
     all_predicates << k
     predicates << k if v <= entropy_threshold
     }
    
     puts "ENTROPY THRESHOLD"
     puts entropy_threshold
    
     [predicates,entropies,all_predicates]
  end

  def discriminability(data)
    triples=[]
    data.each{|x|
      triples = triples + x.map{|s,p,o| [s,p,o] }
    }
    scores = Hash.new
    triples.uniq!
    triples.delete_if{|s,p,o| $textp.include?(p)}
    predicates = triples.map{|s,p,o| p}.uniq
    
    predicates.each{|pred|
      x = triples.map{|s,p,o| o if p == pred}.uniq.compact.size.to_f / triples.map{|s,p,o| [s,p,o] if p == pred}.compact.size.to_f
      scores[pred]= 1 - x
    }
    sorted_ = sort(scores)
    
    _threshold = scores.values.inject{|sum,x| sum + x }.to_f / scores.size.to_f
    all_predicates=[]
    sorted_.each{|k,v|
    puts k
    puts v
    all_predicates << k
    predicates << k if v <= _threshold
    }
    
    return [predicates,scores,all_predicates]
  end

  def normatize(max,value)
    (value / max).abs
  end

  def sort(entropies)
    entropies.sort {|a,b|
      (a[1].abs )<=>(b[1].abs)}
  end

  def   max_entropy_for_n(n)
    -1 * (( 1 / n.to_f) * Math.log(( 1 / n.to_f))  )  * n.to_f
  end

  def entropy (probability)
    probability * Math.log(probability)
  end

  def get_text_properties(rdfdata)

    puts "Computing text properties ... "

    data = Array.new(rdfdata)
    triples=[]
    data.each{|group|
      triples = triples + group
    }
    triples.uniq!
    triples.compact!
    textp=[]
    triples.each{|s,p,o| textp << p if o.to_s.size > 400}
    textp.uniq!
    puts "TEXT PROPERTIES FOUND"
    puts  textp
    puts "END"
    return textp
  end

  ##############################################################################################################################
  def entity_label_filtering(rdfdata)
    $word_by_word_properties.delete("?p")
    discriminative_predicates=$word_by_word_properties
    if $word_by_word_properties.size == 0
      discriminative_predicates = target_discriminative_predicates(rdfdata)
    end

    ######################## SELECTING RESOURCE WITH MAXIMUM STRING SIMILARITY MEASURE PER GROUP ##########################
    count=-1
    rdfdata.map!{|group|

      count=count+1
      # puts "GROUP"
      if group.size > 0
        maximas = group.map{|s,p,o|
          entitylabel = discriminative_predicates.include?(p)
          entitylabel= true if discriminative_predicates.size == 0 # not enough information was used to compute the entropy
          entitylabel = true if (o.to_s.to_i != 0)
          [s,p,o, (!entitylabel || o.instance_of?(RDFS::Resource) or $textp.include?(p) ) ? 0 : (max_jaro(o.to_s, @searchedlabels[count],s).to_f ) ]   }
        # maximas = group.map{|s,p,o|  [s,p,o, (o.instance_of?(RDFS::Resource) or $textp.include?(p)  ) ? 0 : max_jaro(o.to_s, @searchedlabels[count],s).to_f ]   }

        max = maximas.map{|s,p,o,m| m.to_f }.max

        puts  "MAXIMA"
        puts max
        selection = []
        if max > $filter_threshold
          selection = maximas.map{|s,p,o,m| [s,p] if m == max }.uniq.compact
          $word_by_word_properties = selection.map{|s,p| p}.uniq +  $word_by_word_properties
          selection = selection.map{|s,p| s}.uniq
        end
        # selection = maximas.map{|s,p,o,m,e| s if m > $filter_threshold  }.uniq.compact
        # maximas = maximas.map{|s,p,o,m,e| [s,p,o,m,e] if m == max}.uniq.compact if max > $filter_threshold
        # max_entropy = maximas.map{|s,p,o,m,e| e }.max
        # selection = maximas.map {|s,p,o,m,e| s if   e == max_entropy}.uniq.compact  if max > $filter_threshold
        # puts maximas.map{|s,p,o,m| [s,o] if  m == max}.uniq
        # puts selection
        group.delete_if{|s,p,o|  !selection.include?(s)}.compact
      # puts "AFTER SELECTION"
      # puts group.map{|s,p| s}.uniq

      #Special processing for dbpedia due to redirect resources.
      #processing redirect resources

      # group = dbpedia_redirect(group)  if params[:target] == "dbpedia"
      end
      group

    }
    $word_by_word_properties.uniq!
    $word_by_word_properties.compact!
    $word_by_word_properties << "?p" if  $word_by_word_properties.size ==0
    # $word_by_word_properties=$word_by_word_properties[0..1]
    return rdfdata
  end

  def dbpedia_redirect(data)

    redirect = []

    data.each{|s,p,o| redirect << [s,o] if p.to_s.index("wikiPageRedirects") != nil }
    return data if redirect.size == 0
    redirect.uniq!
    subjects = redirect.map{|s,p| s}

    data.delete_if{|s,p,o| subjects.include?(s)   }
    redirect.each{|s,o|
      b= nil
      begin
        b =  Query.new.adapters($session[:target]).sparql("SELECT DISTINCT  ?p ?o  WHERE { #{o} ?p ?o  . } " ).execute
      rescue Exception => ex
        puts "Exception 3 for: #{o}"
        b =  Query.new.adapters($session[:target]).sparql("SELECT DISTINCT  ?p ?o  WHERE { #{o} ?p ?o  . } " ).execute
        puts "******************* EXCEPTION *****************"
        puts ex.message
      end
      b.map!{|p,x| [o,p,x]}
      data = data + b
    }
    data.uniq
  end

  #############################################################################################
  def max_jaro (a,labels,s)
    # puts "COMPUTING MAX JARO ... "
    # puts s
    c = 0
    # puts "LABELS"
    # puts labels
    # puts "-------"
    labels.each{|x|

      c = c + advanced_string_matching(a, x)
    }
    # puts a
    # puts c
    c
  end

  require 'date'

  def valid_date?( str)
    Date.strptime(str,"%m/%d/%Y" ) rescue Date.strptime(str,"%Y-%m-%d" )  rescue false
  end

  ##############################################################################################################################
  def get_first_pivot(instances,limit, offset, labels)
    puts "Obtaining First Pivot"
    resources  = get_ambiguous($instances[offset..(offset+limit-1)], labels)

    subjects = resources[0]
    data = resources[1]
    return if data.size == 1 or data.size == 0

    $origin_subjects =  subjects.map{|s|
      begin
        Query.new.adapters($session[:origin]).sparql("select distinct ?p ?o where { #{s} ?p ?o. }").execute
      rescue Exception => e
        puts "Exception 2 for: #{s}"
        e.message
        Query.new.adapters($session[:origin]).sparql("select distinct ?p ?o where { #{s} ?p ?o. }").execute
      end
    }
    rdf2svm_with_meta_properties(data , [])

    puts "End of Obtaining First Pivot"
  end

  ## GET ENTITY LABELS
  def source_entity_labels(instances)
    puts "source_entity_labels"
    data=[]
    count =0
    instances.each {|s|
      tmp =  Query.new.adapters($session[:origin]).sparql("select ?p ?o where {  #{s.to_s} ?p ?o }").execute
      tmp.map! {|p,o| [s,p,o] }
      data= data + tmp
    }

    $textp = get_text_properties([data])

    data.map! {|s,p,o| [s,p,o] if !$textp.include?(p) }.compact.uniq
    labels = []
    candidates = entropy_computation([data])[0]
    puts "SOURCE CANDIDATES ENTITY LABELS"
    puts candidates

    data.each{|s,p,o|
      labels << p if !$textp.include?(p) and candidates.include?(p) and o.instance_of?(String) and o.size > 3 and (o.to_i.to_s.size != o.to_s.size and o.to_f.to_s.size != o.to_s.size)  #and (o.to_i == 0)
    }
    labels.uniq!

    $textp=nil
    labels.uniq!
    labels = candidates.delete_if{|x| !labels.include?(x)}.compact
    puts "ENTITY LABELS FOUND"
    puts labels
    labels=labels[0..2]
    puts "ENTITY LABELS SELECTED"
    labels.insert(0,"<http://www.w3.org/2000/01/rdf-schema#label>")
    labels.map!{|x| x.to_s}
    labels.uniq!
    puts labels

    labels = labels[0..4]
    puts"SEARCHING STOP WORDS"
    $stopwords=get_stop_words($instances[0..500],labels)

    return labels
  end

  ## GET ENTITY LABELS
  def target_discriminative_predicates(instances)
    puts "target_discriminative_predicates"
    count =0
    data=[]
    instances.each{|group|
      data = data + group
    }
    data.map! {|s,p,o| [s,p,o] if !$textp.include?(p) }.compact.uniq
    labels = []
    candidates = entropy_computation([data])[0]
    puts "TARGET CANDIDATES DISCRIMINATIVE PREDICATES"
    puts candidates

    data.each{|s,p,o|

      labels << p if !$textp.include?(p) and candidates.include?(p) and o.instance_of?(String) and o.size > 3 and (o.to_i.to_s.size != o.to_s.size and o.to_f.to_s.size != o.to_s.size)  #and (o.to_i == 0)
    }

    labels.uniq!
    labels = candidates.delete_if{|x| !labels.include?(x)}.compact
    puts "TARGET  DISCRIMINATIVE PREDICATES FOUND"
    labels.uniq!
    puts labels

    labels

  end

  def get_stop_words(instances, labels)
    puts "STOP WORDS"

    all_stopwords=[]

    labels.each{|label|
      data=[]
      puts "STOP WORDS FOR LABEL: "
      puts label
      stopwords=[]
      size = instances.size
      offset = 0
      while offset < size
        q = instances[offset..(offset+50)].map {|x| " {#{x.to_s} #{label} ?o}"  }.join(" union ")
        data = data +  Query.new.adapters($session[:origin]).sparql("select ?o where { #{q} }  ").execute
        offset = offset+50
      end
      # puts data
      next if data.size == 0
      words=Hash.new

      str = data.map{|o| o.to_s.keyword_normalization.split(" ")}.flatten
      str.each{|x|
        next if x.to_i != 0
        next if x == nil
        # puts x
        words[x] = 0 if words[x] == nil
        words[x] = words[x] + 1
      }
      next if words.size == 0
      size = data.size
      puts "SIZE"
      puts size
      words.each{|x,v|
      # puts x
      # puts v
        words[x] = v.to_f / size.to_f
      }
      # words.sort.each{|x,v|
      # puts x
      # puts v
      #
      # }
      puts "MEDIA / STDEV"
      mm =  mean_and_standard_deviation(words.values)
      mean= mm[0].to_f
      stdev = mm[1].to_f

      puts mean
      puts stdev
      puts "Threshold"
      threshold = mean
      puts threshold
      next if stdev < (mean * 2)
      words = sort(words)
      words.each{|x,v|
      # puts x
      # puts v
        x = x.keyword_normalization.removeaccents
        stopwords << x if v >= (threshold) and x.size > 1
      } #if stdev > 0.1
      stopwords.uniq!
      stopwords =stopwords.sort_by{|x| x.size}
      stopwords.reverse!

      puts stopwords
      puts "END"
      puts stopwords.size
      all_stopwords=all_stopwords + stopwords
    }
    all_stopwords
  end

  ####################################
  def getCode(v)
    ####################################
    #    puts "Getting Code"
    #    @codes=Array.new if @codes == nil
    #    index = @codes.index(v)
    #    return index if index != nil
    #    @codes << v
    #    return @codes.size-1
    ####################################
    @counter=0 if @counter == nil
    @codes=Hash.new if @codes == nil
    c = @codes[v]
    if c == nil
    @counter=@counter+1
    @codes[v]=@counter
    c=@counter
    end
    ####################################
    return  c
  end

end