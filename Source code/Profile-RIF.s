//ʵʱ���eels���ף�ָ������

number token1, token2

class ImageDisplayEventListener : object
{
// Some variables
ROI 	theroi
number 	left, right, SpecialROIID,counter
image spectrum

//Guassian ƽ������
realimage smooth_Is(object self, realimage img, number fwhm, number integ)
{
  realimage Gauss, Gauss_matrix, img_matrix, blur_img, kernal;
  number xsize,ysize, norm, alpha;
  
  //��Сͼ��
  img.GetSize(xsize,ysize)
  number scale=1/5  //ֻ������ͼ
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

  return OutImg 
}



// A function which returns the ROI
ROI GetWin(object self)
{
return theroi
}


// ROIChanged
void ROIChanged( Object self, Number event_flags, ImageDisplay imgdisp, Number roi_change_flags, Number roi_disp_change_flags, ROI theroi )
{
counter=counter+1  //���ڼ�¼ִ�еĴ���

image peaks=imgdisp{"Peaks"}

//ֻ������roi����
number roiflag=1

number thisroiid=theroi.roigetid()
if(thisroiid!=SpecialROIID) //������������ʾroi��ֵ
{
number left, right,xscale,flagBG

getpersistentnumbernote("ElectronDiffraction Tools:PDF:Default Values:Auto BG", flagBG)

If(ControlDown())
{
GetNumber("Auto background (1 or 0)?",flagBG,flagBG)
Setpersistentnumbernote("ElectronDiffraction Tools:PDF:Default Values:Auto BG", flagBG)
}

xscale=spectrum.ImageGetDimensionScale(0)
theroi.roigetrange(left, right)

if(flagBG==1)
{
number x,y,minr,maxr
minr=right-5
maxr=right+5
number minval=peaks[0,minr,1,maxr].min(x,y)
x=minr+x
if(x>10&&x<(spectrum.ImageGetDimensionSize(0)-5))
{
theroi.roisetrange(left,x)
theroi.roisetvolatile(0)
theroi.roisetcolor(1,0,1)
}
else
{
theroi.roisetrange(0.5*spectrum.ImageGetDimensionSize(0),0.5*spectrum.ImageGetDimensionSize(0))
theroi.roisetvolatile(0)
theroi.roisetcolor(1,0,1)
}

theroi.roisetlabel("L="+format(left*xscale,"%4.2f")+" 1/A\nR="+format(x*xscale,"%4.2f")+" 1/A")
}

if(flagBG==0)
{
theroi.roisetvolatile(0)
theroi.roisetcolor(1,0,1)

theroi.roisetlabel("L="+format(left*xscale,"%4.2f")+" 1/A\nR="+format(right*xscale,"%4.2f")+" 1/A")
}
} //��������roi��������

if(OptionDown()&&thisroiid!=SpecialROIID) //ALT+roi��Ѱ��intensity profile�����roi
{
number left, right,l,r
theroi.roigetrange(left, right)

number nodocs=countdocumentwindowsoftype(5) //Ѱ��intensity profile
for(number i=0; i<nodocs; i++)
{
imagedocument imgdoc=getimagedocument(i)
image tempimg:=imgdoc.imagedocumentgetimage(0)

string idstring
getstringnote(tempimg, "Radial Distribution Function",idstring)

number xscale=spectrum.ImageGetDimensionScale(0)

if(idstring=="Intensity Profile")  //roi���Ҳ����intensity profile
{
image IntensityProfile:=tempimg
imagedisplay ProfileDisp=IntensityProfile.ImageGetImageDisplay(0)

//�Ƿ���Ҫ��ӵ�roi
number roino= ProfileDisp.ImageDisplayCountROIS()
for (number i=0; i<roino; i++)
{
roi currentROI = ProfileDisp.ImageDisplayGetROI(i)
currentROI.roigetrange(l,r)

if(right==r)
{
roiflag=0  //����roi
}

}

if(roiflag==1)  //û�������
{
roi roi1=CreateROI()
roi1.roisetrange(right,right)
roi1.roisetvolatile(0)
roi1.roisetcolor(1,0,1)
ProfileDisp.ImageDisplayAddROI( ROI1)

Result("A new ROI is added to Intensity profile at "+right*xscale+" 1/A\n")
}
}
}
}  


if(thisroiid==SpecialROIID) //����roi��ָ������
{
// Source the position of the ROI
number left, right,xscale,xsize,ysize
spectrum.GetSize(xsize,ysize)
xscale=spectrum.ImageGetDimensionScale(0)
theroi.roigetrange(left, right)
number width=right-left
theroi.roisetlabel("Width="+width)

// ��ϱ���
if(counter==1)
{
number fwhm=abs(right-left)
image background=self.smooth_Is(spectrum, fwhm, xsize)
imgdisp.lineplotimagedisplaysetlegendshown(1)

number min1,max1
image Peaks=spectrum/background  //��������ʾ

peaks[0,left,1,0.9*xsize].minmax(min1,max1)
peaks=peaks-peaks[0,left,1,0.9*xsize].min()
peaks=peaks/peaks[0,left,1,0.9*xsize].max()   //��һ��

peaks=spectrum[0,left,1,0.9*xsize].max()*peaks  //�����Iqһ��

imgdisp{"Background"}=background
imgdisp{"Peaks"}=peaks

peaks[0,left,1,0.9*xsize].minmax(min1,max1)
imgdisp.lineplotimagedisplaysetdoautosurvey(0,0)
imgdisp.lineplotimagedisplaysetcontrastlimits(0.9*min1,1.1*max1) //y����ʾ��Χ
}

else if(counter>1&&counter<=3) //��ִ��
{

}

else if(counter>3)
{
counter=0
}

}
}

// ROI is removed
void ROIRemoved( Object self, Number event_flags, ImageDisplay imgdisp, Number roi_change_flags, Number roi_disp_change_flags, ROI theroi )
{
// ֻ������roi����
number thisroiid=theroi.roigetid()
if(thisroiid!=SpecialROIID) return

image img=imgdisp{"Peaks"}
image rif=img
img=img-spectrum.mean()
img=2*img/img.max()
img.imagecopycalibrationfrom(spectrum)
rif.imagecopycalibrationfrom(spectrum)

img.setname("RIF image")
rif.setname("RIF-"+spectrum.getname())

//ɾ������listener��ɾ��ͼ��
imgdisp.ImageDisplayRemoveEventListener(token1)
imgdisp.ImageDisplayRemoveEventListener(token2)
number noslices=imgdisp.imagedisplaycountslices()
number i
for(i=noslices-1; i>-1; i--)
{
object sliceid=imgdisp.imagedisplaygetsliceidbyindex(i)
string slicename=imgdisp.imagedisplaygetslicelabelbyid(sliceid)
if(slicename=="Background" || slicename=="Mean" || slicename=="Peaks") imgdisp.imagedisplaydeleteslicewithid(sliceid)
}

spectrum.deleteimage()
}

// ��ʼ��
object init(object self, image front)
{
spectrum:=front
imagedisplay imgdisp=spectrum.ImageGetImageDisplay(0)
theroi = imgdisp.ImageDisplayGetROI(0)

// ��������roi
SpecialROIID=theroi.roigetid()
theroi.roisetvolatile(0)
theroi.roisetcolor(1,0,0)
theroi.roisetlabel("Width")

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


// ������
void main()
{
// source the front-most image and check that it is a 1D profile
image img:=GetFrontImage()

image front=img
front.SetName("Gaussian BG")
front.ShowImage()
imagedisplay imgdisp=front.imagegetimagedisplay(0)

front.ImageCopyCalibrationFrom(img)
number xscale=img.ImageGetDimensionScale(0)

string isqstring=front.imagegetdimensionunitstring(0)
if(isqstring=="1/?")   //��λΪ1/A
{
xscale=front.imagegetdimensionscale(0)
front.imagesetdimensionscale(0,xscale*2*pi())
front.imagesetdimensionunitstring(0,"Q (1/A)")
}

if(isqstring=="1/nm")  //��λΪ1/nm
{
xscale=front.imagegetdimensionscale(0)
front.imagesetdimensionscale(0,xscale/10*2*pi())
front.imagesetdimensionunitstring(0,"Q (1/A)")
}

if(isqstring=="Q (1/A)")  //��λΪQ (1/A)
{
xscale=front.imagegetdimensionscale(0)
front.imagesetdimensionscale(0,xscale)
front.imagesetdimensionunitstring(0,"Q (1/A)")
}

number xsize, ysize
getsize(front, xsize, ysize)

Result("-----------------------------------------------------------------------------------------\nAlt+ROI: Add the right of ROI to Intensity profile\nCtrl+ROI: to set auto background.\n-----------------------------------------------------------------------------------------\n")

//ɾ������ͼ��
number noslices=imgdisp.imagedisplaycountslices()
for(number i=noslices-1; i>-1; i--)
{
object sliceid=imgdisp.imagedisplaygetsliceidbyindex(i)
string slicename=imgdisp.imagedisplaygetslicelabelbyid(sliceid)
if(slicename=="Bkgd"||slicename=="Background"||slicename=="Peaks") imgdisp.imagedisplaydeleteslicewithid(sliceid)
}

object sliceid=imgdisp.imagedisplaygetsliceidbyindex(0)
imgdisp.imagedisplaysetslicelabelbyid(sliceid, "Raw")
imgdisp.LinePlotImageDisplaySetLegendShown(1)

//�����ͼ��
image slice1=img*0
imgdisp.imagedisplayaddimage(slice1, "Background")  //ͼ��1�����mean
lineplotimagedisplaysetslicedrawingstyle(imgdisp,1,1)
lineplotimagedisplaysetslicecomponentcolor(imgdisp, 1, 0,1,0,0)

image slice2=img*0
imgdisp.imagedisplayaddimage(slice2, "Peaks")  //ͼ��2�����Peaks
lineplotimagedisplaysetslicedrawingstyle(imgdisp,2,1)
lineplotimagedisplaysetslicecomponentcolor(imgdisp, 2, 0,0,0,256)

// ���roi
front.setselection(0,0,1,50)

// listener-image����
// Listener for ROI removal
string messagemap1="roi_removed:ROIRemoved"
object ROIRemovalListener=alloc(ImageDisplayEventListener).init(front)
token1 = imgdisp.ImageDisplayAddEventListener( RoiRemovalListener, messagemap1)

// Listener for ROI change
string messagemap2="roi_changed,roi_Added:ROIChanged"
object ROIChangeListener=alloc(ImageDisplayEventListener).init(front)
token2 = imgdisp.ImageDisplayAddEventListener( RoiChangeListener, messagemap2)
}

// Main script
main()