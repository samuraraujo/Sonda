#Key selection implemented at http://disi.unitn.it/~p2p/RelatedWork/Matching/70310640.pdf
#Automatically Generating Data Linkages Using a Domain-Independent Candidate Selection Approach
#Dezhao Song and Jeﬀ Heﬂin
#Author: Samur Araujo
##########################################################################
class DezhaoSongBasedAligner < XAligner
  def assingment(a,b) 
    a = preparedata(a)
    b = preparedata(b)
    alignment = []
    puts "DEZHAO ALIGNER"
    x = dezhao(a)
    puts "SELECTED"
    puts x
     puts "DEZHAO ALIGNER 1"
    y = dezhao(b)
    puts "SELECTED 1"
    puts y
    exit
    # puts "ALIGNMENT"
    # puts alignment
    return alignment.compact
  end

  def dezhao(a)
    satisfied=false
    alpha=0.7
    beta=0.5
    scores=Hash.new
    keyset = a.map{|s,p,o| p}.uniq
    while  !satisfied and !keyset.empty?
      keyset.each{|key|
        disc = discriminability(a,key)
        if disc < beta then
        keyset.delete(key)
        else
          cover = coverage(a,key)
          fl = (2 * disc * cover).to_f / (disc+cover).to_f
          scores[key]=fl
          if fl > alpha
          satisfied = true
          end
        end
      }
      if !satisfied
        dis_key = keyset.map{|key| discriminability(a,key)}
        puts "dis_key"
        puts dis_key
        max = dis_key.max
        puts max
        dis_key = keyset[dis_key.index(max)]
        puts "SELECTED"
        puts dis_key
        keyset.delete(dis_key)
        keyset.map!{|x| dis_key.to_s + " " + x.to_s}
        # puts "keyset"
        # keyset.each{|x| puts "X"
          # puts x}
        a = update(dis_key,keyset, a)
      end
     
    end
    # maxk = 0
    # k = nil
    # scores.keys.each{|key|
      # if maxk < scores[key]
      # maxk = scores[key]
      # k=key
      # end
    # }
    return scores.keys
  end

  def update(diskey,keyset, a)
      b = []
      sub = Hash.new
      a.each{|s,p,o| sub[s]=o if p == diskey}
      return a.map{|s,p,o| 
         [s, diskey.to_s + " " + p.to_s, sub[s].to_s + o.to_s] if p != diskey
        }.compact
  end

  def discriminability(a,pred)
    x = a.map{|s,p,o| o if p == pred}.uniq.compact.size.to_f / a.map{|s,p,o| s if p == pred}.uniq.compact.size.to_f
    puts "DISCRIMINABILTY"
    puts pred
    puts x
    return x
  end

  def coverage(a,pred)
    a.map{|s,p,o| s if p == pred}.uniq.compact.size.to_f / a.map{|s,p,o| s }.uniq.compact.size.to_f
  end
end
