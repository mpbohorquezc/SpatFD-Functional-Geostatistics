CrossSpatFD <-
  function(data,coords,basis,lambda=0,nharm=NULL,name=NULL,add=NULL,...){
    #----------------------------------------------------------------------------
    #           VALIDANDO ARGUMENTOS *
    #----------------------------------------------------------------------------
    # jocastroc:vp no funciona, se define null por si se quiere volver a implementar en el código.
    # LelielC: No usar directamente, este objeto solo se usa al interior de la validación cruzada
    vp=NULL
    nbasis <- basis$nbasis
    # jocastroc2:Recuperar argumentos de la llamada del objeto
    call_args=list(data=data,coords=coords,basis=basis,lambda=lambda,nharm=nharm,name=name,add=add,...)
    
    #all
    if(missing(data)){
      stop("Missing data")
    }
    if (missing(coords)){
      stop("Missing coords")
    }
    if(missing(nharm) && missing(vp)){
      stop("Missing nharm or vp")
    }
    
    #data
    if(!(is.matrix(data) || is.array(data) || is.data.frame(data) ||fda::is.fdSmooth(data)||fda::is.fd(data))){
      stop("Wrong class of data object")
    }
    if(any(is.na(data))){
      stop("There is some NA value in data")
    }
    #coords
    
    if(!(is.matrix(coords) || is.data.frame(coords))){
      stop("Wrong class of coords object")
    }else if(!all(apply(coords, c(1,2), is.numeric))){
      stop("Coords must be numeric data")
    }else if(any(is.na(coords))){
      stop("There is some NA value in coords")
    }
    #Coincidan tamaños
    if(is.matrix(data)||is.data.frame(data)|| is.array(data)){
      cx=dim(data)[2]
    }else if(fda::is.fdSmooth(data)){
      cx=dim(data$fd$coefs)[2]
    }else if(fda::is.fd(data)){
      cx=dim(data$coefs)[2]
    }
    
    fc=dim(coords)[1]
    
    if(cx!=fc){
      stop("Number of columns of data must be equal to number of rows of coords")
    }
    
    # basis and nharm
    if(nbasis<nharm){
      stop("Number of basis must be equal or greater than number of harmonics (nharn)")
    }
    
    #nbasis
    if (!(((fda::is.fdSmooth(data)||fda::is.fd(data) )&&is.null(nbasis))  || (is.numeric(nbasis)&& length(nbasis)==1))){
      stop("Wrong class of nbasis object")
    }
    #nharm
    if (!(is.null(nharm)  || (is.numeric(nharm)&& length(nharm)==1))){
      stop("Wrong class of nharm object")
    }
    #lambda
    if (!(((fda::is.fdSmooth(data)||fda::is.fd(data) )&&is.null(lambda))  || (is.numeric(lambda)&& length(lambda)==1))){
      stop("Wrong class of lambda object")
    }
    #vp
    if (!( is.null(vp)  || (is.numeric(vp)&& length(vp)==1))){
      stop("Wrong class of vp object")
    }
    
    #add
    if(!(is.null(add) || inherits(add,"SpatFD"))){
      stop("Wrong class of add object")
    }
    
    #name
    if (is.null(name)){
      name=deparse(substitute(data))
    }
    if (!(is.character(name)&& length(name)==1)){
      stop("Wrong class of name object")
    }
    if(name %in% names(add)){
      stop("Change name, it already exists.")
    }
    
    #----------------------------------------------------------------------------
    #           DEJANDO LISTO PARA FPCA
    #----------------------------------------------------------------------------
    
    
    if(is.matrix(data) || is.array(data) || is.data.frame(data)){
      if(missing(basis)){
        message("Using Bsplines basis by default")
      }
      if(missing(nbasis)){
        message("Using 4 basis by default")
      }
      if(missing(lambda)){
        message("Using lambda = 0 by default")
      }
      Mdata=as.matrix(data)
      if(!is.numeric(Mdata)){
        stop("Object data is not numeric")
      }
      
      hr <- c(1,nrow(Mdata))
      oplfd <- fda::vec2Lfd(c(1,ncol(Mdata)), hr)
      
      #bases funcionales
      hourbasis <- basis
      
      data_fdPar<-fda::fdPar(fdobj=hourbasis,Lfdobj=oplfd,lambda)
      data_fdSm <- fda::smooth.basis(argvals=1:nrow(Mdata),Mdata,data_fdPar)
      data_fd=data_fdSm$fd
      cn=data_fd$fdnames$reps
      
    }  else if (fda::is.fdSmooth(data)){
      data_fdSm = data
      data_fd=data_fdSm$fd
      cn=data_fd$fdnames$reps
    }  else if (fda::is.fd(data)){
      data_fd=data
      cn=data_fd$fdnames$reps
    }
    call_args$basisfd <- data_fd$basis
    #----------------------------------------------------------------------------
    #            FPCA
    #----------------------------------------------------------------------------
    
    if (!is.null(nharm)){
      fpca=fda::pca.fd(data_fd,nharm=nharm)
    }  else if(!is.null(vp)){
      nh=1
      repeat{
        fpca=fda::pca.fd(data_fd,nharm = nh)
        if(! sum(fpca$varprop)<vp){ break }
        nh=nh+1
      }
    }  else if(is.null(nharm) && is.null(vp)){
      fpca=fda::pca.fd(data_fd)
    }
    
    if(is.null(add)){
      s=list(list(data=data, coords=coords,coordsnames=cn, data_fd = data_fd, fpca=fpca, variable_name= name, call_args=call_args))
      names(s)=name
      class(s)="SpatFD"
    }  else if (inherits(add,"SpatFD")){
      s=list(list(data=data,coords=coords,data_fd=data_fd,coordsnames=cn,fpca=fpca, variable_name=name, call_args=call_args))
      names(s)=name
      s=append(add,s)
      class(s)="CrossSpatFD"
    }
    
    return(s)
  }
