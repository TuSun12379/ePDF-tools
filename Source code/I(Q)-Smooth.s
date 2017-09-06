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
  number scale=1/5 //ֻ������ͼ
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

//ֻ������roi����
number roiflag=1

number thisroiid=theroi.roigetid()
if(thisroiid!=SpecialROIID) //������������ʾroi��ֵ
{
number left, right,xscale,flagBG

getpersistentnumbernote("ElectronDiffraction Tools:PDF:Default Values:Auto BG", flagBG)

xscale=spectrum.ImageGetDimensionScale(0)
theroi.roigetrange(left, right)
} //��������roi��������


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
number fwhm=0.1*abs(right-left)
image background=self.smooth_Is(spectrum, fwhm, xsize)
imgdisp.lineplotimagedisplaysetlegendshown(1)
imgdisp{"Background"}=background

if(OptionDown())
{
image new=spectrum
number flag=1
GetNumber("Which part of the ROI will be replaced, left, right, or all (0, 1, 2)",flag,flag)

if(flag==0)  //left
{
new[0,0,1,left]=background[0,0,1,left]
}

if(flag==1)//right
{
new[0,right,1,xsize]=background[0,right,1,xsize]
}

if(flag==2)
{
new[0,0,1,xsize]=background[0,0,1,xsize]
}

imgdisp{"Smoothed"}=new
}

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

image img=imgdisp{"Smoothed"}
img.imagecopycalibrationfrom(spectrum)
img.setname("Gaussian smoothed")
//setstringnote(img,"Radial Distribution Function","Reduced Density Function")	
img.ShowImage()


//ɾ������listener��ɾ��ͼ��
imgdisp.ImageDisplayRemoveEventListener(token1)
imgdisp.ImageDisplayRemoveEventListener(token2)
number noslices=imgdisp.imagedisplaycountslices()
number i
for(i=noslices-1; i>-1; i--)
{
object sliceid=imgdisp.imagedisplaygetsliceidbyindex(i)
string slicename=imgdisp.imagedisplaygetslicelabelbyid(sliceid)
if(slicename=="Background" ) imgdisp.imagedisplaydeleteslicewithid(sliceid)
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
if(slicename=="Background") imgdisp.imagedisplaydeleteslicewithid(sliceid)
}

object sliceid=imgdisp.imagedisplaygetsliceidbyindex(0)
imgdisp.imagedisplaysetslicelabelbyid(sliceid, "Raw")
imgdisp.LinePlotImageDisplaySetLegendShown(1)

//�����ͼ��
image slice1=img*0
imgdisp.imagedisplayaddimage(slice1, "Background")  //ͼ��1��background
lineplotimagedisplaysetslicedrawingstyle(imgdisp,1,1)
lineplotimagedisplaysetslicecomponentcolor(imgdisp, 1, 0,1,0,0)

image slice2=img*0
imgdisp.imagedisplayaddimage(slice2, "Smoothed")  //ͼ��2��smoothed
lineplotimagedisplaysetslicedrawingstyle(imgdisp,2,1)
lineplotimagedisplaysetslicecomponentcolor(imgdisp, 2, 0,1,0,1)

// ���roi
number t,l,b,r
img.GetSelection(t,l,b,r)
if(l!=0&&r!=xsize)front.setselection(t,l,b,r)

else front.setselection(0,0.1*xsize,1,0.1*xsize+50)

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