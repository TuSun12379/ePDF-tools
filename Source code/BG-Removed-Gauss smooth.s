 //Iq��˹ƽ���������˹���ף���Fq
realimage smooth_Fq(object self, realimage img, number fwhm, number integ)
{
  realimage Gauss, Gauss_matrix, img_matrix, blur_img, kernal;
  number xsize,ysize, norm, alpha,n=2
  
  //��Сͼ��
  img.GetSize(xsize,ysize)
  number scale=1/n //ֻ������ͼ
  Image SmallImg:= RealImage("",4,xsize*scale,1) 
  SmallImg =warp(img,icol/scale,irow/1)

  number xsize1,ysize1
  SmallImg.GetSize(xsize1,ysize1)
  
  //�����˹����
  fwhm=fwhm*scale
  Gauss = exprsize(1,xsize1,0)
  alpha = log(2)*4.0/(fwhm)**2;
  Gauss = exp(-alpha*((icol-ysize1/2)**2+(irow-xsize1/2)**2));
  Gauss/=sum(Gauss)
    
  kernal       = exprsize(xsize1,xsize1,0);
  blur_img     = exprsize(xsize1,0);
  Gauss_matrix = exprsize(xsize1,xsize1,0);
  img_matrix   = exprsize(xsize1,xsize1,0);

  slice2(Gauss_matrix, 0, 0, 0, 0, xsize1, 1, 1, xsize1, 1)   = Gauss[0,irow+xsize1/2-xsize1/xsize1*icol]; 
  slice2(img_matrix, 0, 0, 0,   0, xsize1, 1, 1, xsize1, 1)   = SmallImg[irow,0]; 
 
  kernal = Gauss_matrix*img_matrix;
  if((xsize1+1)%2==0) //Don't use Simpson if this condition is not satisfied.  Just becomes skyscraper summation instead
    kernal *= (4*(irow%2)+2*((irow+1)%2))/3.0*tert(irow==0,0,1)*tert(irow==xsize1-1,0,1)+tert(irow==0,1,0)+tert(irow==xsize1-1,1,0)
  blur_img[icol,0] += slice2(kernal, 0, 0, 0, 0, xsize1, 1, 1, xsize1, 1); //integration summation

  //��ԭ
  realimage OutImg=img*0
  OutImg=warp(blur_img,icol*scale,irow*1)
  
  number x0=xsize-(n+1)  
  number k=outimg.GetPixel(x0,0)-outimg.GetPixel(x0-1,0)
  number c=outimg.GetPixel(x0,0)-k*x0
  for(number i=x0;i<xsize;i++)
  {
  outimg.SetPixel(i,0,k*i+c)
  }  

  return OutImg 
}

 
//Guassian ƽ������
realimage smooth_Is(object self, realimage img, number fwhm, number integ)
{
  realimage Gauss, Gauss_matrix, img_matrix, blur_img, kernal;
  number xsize,ysize, norm, alpha,n=5
  
  //��Сͼ��
  img.GetSize(xsize,ysize)
  number scale=1/n  //ֻ������ͼ
  Image SmallImg:= RealImage("",4,xsize*scale,1) 
  SmallImg =warp(img,icol/scale,irow/1)

  number xsize1,ysize1
  SmallImg.GetSize(xsize1,ysize1)
  
  //�����˹����
  fwhm=fwhm*scale
  Gauss = exprsize(1,xsize1,0)
  alpha = log(2)*4.0/(fwhm)**2;
  Gauss = exp(-alpha*((icol-ysize1/2)**2+(irow-xsize1/2)**2));
  Gauss/=sum(Gauss)
    
  kernal       = exprsize(xsize1,xsize1,0);
  blur_img     = exprsize(xsize1,0);
  Gauss_matrix = exprsize(xsize1,xsize1,0);
  img_matrix   = exprsize(xsize1,xsize1,0);

  slice2(Gauss_matrix, 0, 0, 0, 0, xsize1, 1, 1, xsize1, 1)   = Gauss[0,irow+xsize1/2-xsize1/xsize1*icol]; 
  slice2(img_matrix, 0, 0, 0,   0, xsize1, 1, 1, xsize1, 1)   = SmallImg[irow,0]; 
 
  kernal = Gauss_matrix*img_matrix;
  if((xsize1+1)%2==0) //Don't use Simpson if this condition is not satisfied.  Just becomes skyscraper summation instead
    kernal *= (4*(irow%2)+2*((irow+1)%2))/3.0*tert(irow==0,0,1)*tert(irow==xsize1-1,0,1)+tert(irow==0,1,0)+tert(irow==xsize1-1,1,0)
  blur_img[icol,0] += slice2(kernal, 0, 0, 0, 0, xsize1, 1, 1, xsize1, 1); //integration summation

  //��ԭ
  realimage OutImg=img*0
  OutImg=warp(blur_img,icol*scale,irow*1)
  
  number x0=xsize-(n+1)  
  number k=outimg.GetPixel(x0,0)-outimg.GetPixel(x0-1,0)
  number c=outimg.GetPixel(x0,0)-k*x0
  for(number i=x0;i<xsize;i++)
  {
  outimg.SetPixel(i,0,k*i+c)
  }

  return OutImg 
}


number token1   //listener1  ����roichanged
number token2  //listener2  ����ȡ��listener

// ������
class ImageDisplayEventListener : object
{
//�������		
ROI 	theroi
number  left, right, SpecialROIID,counter
image spectrum
	
	// ��׽ROI	
	ROI GetWin(object self) 
		{
			return theroi
		}

		
void ROIChanged( Object self, Number event_flags, ImageDisplay imgdisp, Number roi_change_flags, Number roi_disp_change_flags, ROI theroi )
{		
counter=counter+1  //���ڼ�¼ִ�еĴ���

if(counter==1)
{
number thisroiid=theroi.roigetid()

//����һЩͼ
image Iq=spectrum*1
image peaks=spectrum*0
image f2q=imgdisp{"<f>2"}   //<f>2
image fq2=imgdisp{"<f2>"}  //<f2>
image Fq=spectrum*0
image splineimg=spectrum*0
image smooth=spectrum

number integral_peaks, integral_fq2,n,c,left,right,x,y,minx,maxx
number xsize, ysize,xscale,scale
spectrum.getsize(xsize,ysize)
xscale=spectrum.ImageGetDimensionScale(0)

//Ѱ��roi
number roino= imgdisp.ImageDisplayCountROIS()
for (number i=0; i<roino; i++)
{
ROI currentROI = imgdisp.ImageDisplayGetROI( i )
string thischar=currentROI .ROIGetLabel()
string roilabel=left(thischar,1)

number l,r
if(roilabel=="C")
{
currentROI.ROIGetRange(l,r)
currentROI.roisetlabel("C")
setnumbernote(spectrum,"ElectronDiffraction Tools:PDF:Parameters:End:Left",l)
setnumbernote(spectrum,"ElectronDiffraction Tools:PDF:Parameters:End:Right",r)  
}

if(roilabel=="B")
{
currentROI.ROIGetRange(l,r)
currentROI.roisetlabel("BG="+abs(r-l))
setnumbernote(spectrum,"ElectronDiffraction Tools:PDF:Parameters:FWHM",abs(r-l)) 
setnumbernote(spectrum,"ElectronDiffraction Tools:PDF:Parameters:Front",l) 
}

if(roilabel=="S")
{
currentROI.ROIGetRange(l,r)
currentROI.roisetlabel("Smooth="+0.1*abs(r-l))
setnumbernote(spectrum,"ElectronDiffraction Tools:PDF:Parameters:Smooth:FWHM",0.1*abs(r-l)) 
setnumbernote(spectrum,"ElectronDiffraction Tools:PDF:Parameters:Smooth:RightPart",r) 
}
}


number front,end,fwhm,SmoothWidht,SmoothRight
getnumbernote(spectrum,"ElectronDiffraction Tools:PDF:Parameters:Front",front) 
getnumbernote(spectrum,"ElectronDiffraction Tools:PDF:Parameters:End:Left",left)
getnumbernote(spectrum,"ElectronDiffraction Tools:PDF:Parameters:End:Right",right) 
getnumbernote(spectrum,"ElectronDiffraction Tools:PDF:Parameters:FWHM",fwhm) 

getnumbernote(spectrum,"ElectronDiffraction Tools:PDF:Parameters:Smooth:FWHM",SmoothWidht) 
getnumbernote(spectrum,"ElectronDiffraction Tools:PDF:Parameters:Smooth:RightPart",SmoothRight) 

//�ȶ�Iqƽ��
image smoothIq=self.smooth_Fq(spectrum, SmoothWidht, xsize)
Smooth=spectrum
Smooth[0,SmoothRight,1,xsize]=smoothIq[0,SmoothRight,1,xsize]
imgdisp{"Smooth"}=smooth

//ȡIq�ĸ�˹����
image background=self.smooth_Is(Smooth, fwhm, xsize)
imgdisp.lineplotimagedisplaysetlegendshown(1)

Peaks=Smooth-background  //��������ʾ
Peaks[0,0,1,front]=Peaks.GetPixel(front,0)

//���㳣��c
number fittingchannels
getpersistentnumbernote("ElectronDiffraction Tools:PDF:Default Values:Fit to Top channel %",fittingchannels)
fittingchannels=1-(fittingchannels/100)

if(fittingchannels>0.99) fittingchannels=0.99
if(fittingchannels<0.01) fittingchannels=0.01	

c=fq2.GetPixel(0.5*(left+right),0)-peaks.GetPixel(0.5*(left+right),0)/2
Fq=(icol*xscale)*(Peaks-fq2+c)/(f2q) 

setnumbernote(spectrum,"ElectronDiffraction Tools:PDF:Parameters:N",1)
setnumbernote(spectrum,"ElectronDiffraction Tools:PDF:Parameters:C",c)
setnumbernote(spectrum,"ElectronDiffraction Tools:PDF:Parameters:N0",1) 

imgdisp{"Background"}=background
imgdisp{"I(Q)"}=peaks
imgdisp{"F(Q)"}=Fq

number min1,max1
imgdisp{"F(Q)"}.minmax(min1,max1)

//imgdisp.LinePlotImageDisplaySetContrastLimits(1.1*min1,1.1*max1)
//imgdisp.LinePlotImageDisplaySetDoAutoSurvey(0,0)
}

else if(counter>1&&counter<=5) //��ִ��
{
}

else if(counter>5)
{
counter=0
}
}

// �½�roiʱɾ��listener��ɾ������roi����ȡ��peaks
void ROIRemoved( Object self, Number event_flags, ImageDisplay imgdisp, Number roi_change_flags, Number roi_disp_change_flags, ROI theroi )
{
// ֻ������roi����			
number thisroiid=theroi.roigetid()
if(thisroiid!=SpecialROIID) return	

//ɾ����ʱ����
TagGroup tg = spectrum.ImageGetTagGroup()
TagGroup tg1
if(tg.taggroupgettagastaggroup("ElectronDiffraction Tools:Background", tg1))
deletenote(spectrum, "ElectronDiffraction Tools:Background")
deletepersistentnote("ElectronDiffraction Tools:PDF:ROIs")

//�Ƴ�token
imgdisp.ImageDisplayRemoveEventListener(token1)
imgdisp.ImageDisplayRemoveEventListener(token2)

spectrum=imgdisp{"I(Q)"}

//����roi�����棬����ɾ��roi
number l,r,x,xsize,ysize
spectrum.GetSize(xsize,ysize)

theroi.ROIGetRange(l,r)
setpersistentnumbernote("ElectronDiffraction Tools:PDF:Fit Range:Lower",l)
setpersistentnumbernote("ElectronDiffraction Tools:PDF:Fit Range:Upper",xsize)

number roino= imgdisp.ImageDisplayCountROIS()
for (number i=0; i<roino; i++)
{
ROI currentROI = imgdisp.ImageDisplayGetROI(i)

currentROI.roigetrange(l,r)
x=r/1000 //Ϊ��������
setpersistentnumbernote("ElectronDiffraction Tools:PDF:ROIs:"+x+":X",r)
}

for (number i=0; i<roino; i++)
{
ROI currentROI = imgdisp.ImageDisplayGetROI(0)
imgdisp.imagedisplaydeleteROI(currentROI)
}

//ɾ�����õ�ͼ��
number noslices=imgdisp.imagedisplaycountslices()
for(number i=noslices-1; i>-1; i--)
{
object sliceid=imgdisp.imagedisplaygetsliceidbyindex(i)
string slicename=imgdisp.imagedisplaygetslicelabelbyid(sliceid)
if(slicename=="Background"||slicename=="I(Q)"||slicename=="Smooth") imgdisp.imagedisplaydeleteslicewithid(sliceid)
}

object sliceid=imgdisp.imagedisplaygetsliceidbyindex(0)
imgdisp.imagedisplaysetslicelabelbyid(sliceid, "I(Q)")

number min1,max1
imgdisp{"F(Q)"}.minmax(min1,max1)

imgdisp.lineplotimagedisplaysetdisplayedchannels(0,xsize) 
imgdisp.LinePlotImageDisplaySetContrastLimits(1.1*min1,1.1*max1)
imgdisp.LinePlotImageDisplaySetDoAutoSurvey(0,0)
}
	
		
// This function sources the ROI on the passed in image
		object init(object self, image front)
		{
			spectrum:=front
			imagedisplay imgdisp=spectrum.ImageGetImageDisplay(0)			
			
			// �ѵ�һ��roi��������roi	
			theroi = imgdisp.ImageDisplayGetROI(0)				
			SpecialROIID=theroi.roigetid()			
			//theroi.roisetrange(20,70)
			theroi.roisetvolatile(0)
			theroi.roisetcolor(0,1,0)
			theroi.roisetlabel("BG")	
			
			// ����roi����Ӧ			
			number dummy=0
			self.roichanged(dummy, imgdisp, dummy, dummy, theroi)
			
			return self			
		}
		
	// Constructor
	ImageDisplayEventListener(object self)
		{

		}
		
	// Destructor
	~ImageDisplayEventListener(object self)
		{
		}
}


void main()
{
image img:=getfrontimage()
imagedisplay imgdisp=imagegetimagedisplay(img, 0)
string imgname=img.getname()

number xsize, ysize
getsize(img, xsize, ysize)

//�������ͼ�㣬�Ա����
number noslices=imgdisp.imagedisplaycountslices()
for(number i=noslices-1; i>-1; i--)
{
object sliceid=imgdisp.imagedisplaygetsliceidbyindex(i)
string slicename=imgdisp.imagedisplaygetslicelabelbyid(sliceid)
if(slicename=="Background"||slicename=="I(Q)"||slicename=="F(Q)"||slicename=="Smooth") imgdisp.imagedisplaydeleteslicewithid(sliceid)
}

image slice3=img*0
imgdisp.imagedisplayaddimage(slice3, "Background")  //ͼ��4�����Background
lineplotimagedisplaysetslicedrawingstyle(imgdisp,3,1)
lineplotimagedisplaysetslicecomponentcolor(imgdisp, 3, 0,0,0,1)

image slice4=img*0
imgdisp.imagedisplayaddimage(slice4, "I(Q)")  //ͼ��5�����I(Q)
lineplotimagedisplaysetslicedrawingstyle(imgdisp,4,1)
lineplotimagedisplaysetslicecomponentcolor(imgdisp, 4, 0,1,0,0)

image slice5=img*0
imgdisp.imagedisplayaddimage(slice5, "F(Q)")  //ͼ��6�����F(Q)
lineplotimagedisplaysetslicedrawingstyle(imgdisp,5,1)
lineplotimagedisplaysetslicecomponentcolor(imgdisp, 5, 0,0,0,1)

image slice6=img*0
imgdisp.imagedisplayaddimage(slice6, "Smooth")  //ͼ��6�����F(Q)
lineplotimagedisplaysetslicedrawingstyle(imgdisp,6,1)
lineplotimagedisplaysetslicecomponentcolor(imgdisp, 6, 0,1,0,1)

//��ʾ��
result("--------------------------------------------------------------------------\nROI changed: fit Background\nCtrl+ROI: to set auto background."+"--------------------------------------------------------------------------\n")

//----------------------------------------��ʼ�Զ�Ѱ�ұ���-------------------
//ɾ����ʱ����
TagGroup tg = img .ImageGetTagGroup()
TagGroup tg1
if(tg.taggroupgettagastaggroup("ElectronDiffraction Tools:Background", tg1)) tg1.TagGroupDeleteAllTags()

///�����ʼĩ����roi���Զ�ʶ��Сֵ
roi roi1=createroi()
ROI1.ROISetrange(0.1*xsize-25,0.1*xsize+25)
imgdisp.ImageDisplayAddROI( ROI1)
roi1.roisetlabel("BG")
roi1.roisetvolatile(0)

roi1=createroi()
ROI1.ROISetrange(0.9*xsize-10,0.9*xsize)
imgdisp.ImageDisplayAddROI( ROI1)
roi1.roisetlabel("C")
roi1.roisetcolor(0,0,1)
roi1.roisetvolatile(0)

roi1=createroi()
ROI1.ROISetrange(0.5*xsize-10,0.5*xsize+10)
imgdisp.ImageDisplayAddROI( ROI1)
roi1.roisetlabel("Smooth")
roi1.roisetcolor(1,0,0)
roi1.roisetvolatile(0)

// listener-image����
// Listener for ROI removal
string messagemap1="roi_removed:ROIRemoved"
object ROIRemovalListener=alloc(ImageDisplayEventListener).init(img)
token1 =imgdisp.ImageDisplayAddEventListener( RoiRemovalListener, messagemap1)

// Listener for ROI change
string messagemap2="roi_changed,roi_added,roi_removed:ROIChanged"
object ROIChangeListener=alloc(ImageDisplayEventListener).init(img)
token2 =imgdisp.ImageDisplayAddEventListener( RoiChangeListener, messagemap2)		
}


// Main script
main()
