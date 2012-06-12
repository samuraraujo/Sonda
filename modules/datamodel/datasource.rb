$session = Hash.new
module DataSourceModule
 #initialize the source and target dataset source object connector
  def connect(params)
    params[:source] = $endpoints[params[:source].to_sym] if params[:source].downcase.index("http") == nil
    params[:target] = $endpoints[params[:target].to_sym] if params[:target].downcase.index("http") == nil

    origin_endpoint=params[:source]
    target_endpoint=params[:target]

    # $dbpedia = params[:target].index("dbpedia") != nil

    $session[:origin] = mount_adapter(origin_endpoint,:post,false)
    $session[:target] = mount_adapter(target_endpoint,:post,false)
  end
  def mount_adapter(endpoint, method=:post,cache=true)

    adapter=nil
    begin
      adapter = ConnectionPool.add_data_source :type => :sparql, :engine => :virtuoso, :title=> endpoint , :url =>  endpoint, :results => :sparql_xml, :caching => cache , :request_method => method

    rescue Exception => e
      puts e.getMessage()
      return nil
    end
    return adapter
  end
   def intersection_query(subjects, dataset)
    q = subjects.map {|x| "   #{x.to_s}  ?p  ?o . "  }.join(" ")
    return [] if q == ""
    data =  Query.new.adapters(dataset).sparql("select distinct * where { #{q} }  ").execute
  end

  def union_query(subjects, dataset)
    subjects.compact! 
    if subjects.size > 0 
     
    subjects.delete_if{|x| !x.instance_of?(String) && !x.instance_of?(RDFS::Resource)  && x[0].bnode?  } 
    
    end
   
    size = subjects.size
      
    offset = 0
    data=[]
    while offset < size
      
      q = subjects[offset..(offset+30-1)].map {|x| " { ?s  ?p  ?o . filter (?s = #{x.to_s}) }"  }.join(" union ")
      return [] if q == ""
     
      data = data + Query.new.adapters(dataset).sparql("select distinct * where { #{q}}  ").execute
     
      offset = offset+30
    end
    return data
  end

end