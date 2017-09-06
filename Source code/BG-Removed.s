 // ���Զ�Ѱ�ҵ����ݵ�Ϊ�����������ֶ�ʵʱ��ϱ���
 //ȷ������ElectronDiffraction Tools:Fit:Smooth factor�Ļ��棬����������������
 //number s=2,start=120,end=1200
//setpersistentnumbernote("ElectronDiffraction Tools:Fit:Smooth factor",s)
//setpersistentnumbernote("ElectronDiffraction Tools:Fit:Start",start)
//setpersistentnumbernote("ElectronDiffraction Tools:Fit:End",end)
 
//����
 number T(image f, number x, number y, number z)  //z is step
{
number h,Tn, i
h=(y-x)/z;
Tn=(f.GetPixel(x,0)+f.GetPixel(y,0))/2;
for(i=1;i<z;i++)Tn=Tn+f.GetPixel(x+i*h,0)

Tn=Tn*h;
return (Tn);
}


  image calculatesplineconstants(image dataset)
{
// variables
number n, sizex, sizey, minx, maxx, yspline, i, prevval, thisx,m,j
getsize(dataset, sizex, sizey)

// the number of data points
n=sizex-1

// ���ڴ洢x��y����
image x=realimage("",4,sizex+1, 1)
image a=realimage("",4,sizex+1, 1)
image xa=realimage("",4,sizex+1, 1)
image h=realimage("",4,sizex+1, 1)

image xl=realimage("",4,sizex+1, 1)
image xu=realimage("",4,sizex+1, 1)
image xz=realimage("",4,sizex+1, 1)

image b=realimage("",4,sizex+1, 1)
image c=realimage("",4,sizex+1, 1)
image d=realimage("",4,sizex+1, 1)

image constantarray=realimage("",4,sizex+1,5) // stores all the constants and the x values
x[0,1,1,sizex+1]=dataset[0,0,1,sizex]
a[0,1,1,sizex+1]=dataset[1,0,2,sizex]

setpixel(xl,1,0,1)
setpixel(xu,1,0,0)
setpixel(xz,1,0,0)

// Step 1
m=n-1
for(i=0; i<m+1;i++)
{
h[0,i+1,1,i+2]=getpixel(x,i+2,0)-getpixel(x, i+1,0)

if(i>0)
{
xa[0,i+1,1,i+2]=3*(getpixel(a,i+2,0)*getpixel(h,i,0)-getpixel(a,i+1,0)*(getpixel(x,i+2,0)-getpixel(x,i,0))+getpixel(a,i,0)*getpixel(h,i+1,0))/(getpixel(h,i+1,0)*getpixel(h,i,0))

xl[0,i+1,1,i+2]=2*(getpixel(x,i+2,0)-getpixel(x,i,0))-getpixel(h,i,0)*getpixel(xu,i,0)
xu[0,i+1,1,i+2]=getpixel(h,i+1,0)/getpixel(xl,i+1,0)
xz[0,i+1,1,i+2]=(getpixel(xa,i+1,0)-getpixel(h,i,0)*getpixel(xz,i,0))/getpixel(xl,i+1,0)
}
}

// Step 2
setpixel(xl,n+1,0,1)
setpixel(xz,n+1,0,0)
setpixel(c,n+1,0,getpixel(xz,n+1,0))

// step 3
for(i=0;i<m+1;i++)
{
j=m-i
c[0,j+1,1,j+2]=getpixel(xz,j+1,0)-getpixel(xu,j+1,0)*getpixel(c,j+2,0)
b[0,j+1,1,j+2]=(getpixel(a,j+2,0)-getpixel(a,j+1,0))/getpixel(h,j+1,0)-getpixel(h,j+1,0)*(getpixel(c,j+2,0)+2*getpixel(c,j+1,0))/3
d[0,j+1,1,j+2]=(getpixel(c,j+2,0)-getpixel(c,j+1,0))/(3*getpixel(h,j+1,0))
}

// Copy the a, b, c and d images to the array image and return it
constantarray[0,0,1,sizex+1]=a[0,0,1,sizex+1]
constantarray[1,0,2,sizex+1]=b[0,0,1,sizex+1]
constantarray[2,0,3,sizex+1]=c[0,0,1,sizex+1]
constantarray[3,0,4,sizex+1]=d[0,0,1,sizex+1]
constantarray[4,0,5,sizex+1]=x[0,0,1,sizex+1]

return constantarray
}

//��abcd���㱳��
number fastcubicspline(image constantarray, number xvalue, number extrapolate)
{
number minx, maxx, sizex, sizey, yspline, i, n

getsize(constantarray, sizex, sizey)
minmax(constantarray[4,1,5,sizex], minx, maxx) // ignore position 0

// �Ƿ�����
if(extrapolate==0)
{
if(xvalue<minx || xvalue>maxx)
{
yspline=0
return yspline
}
}

n=sizex-2 // note - 2 because pixel position 0 is unused.
for(i=1;i<n;i++)
{
if(xvalue<getpixel(constantarray,1,4)) break
if(xvalue>=getpixel(constantarray,i,4) && xvalue<getpixel(constantarray,i+1,4)) break
}

// Compute the spline a=row 0, b=row 1, c=row 2 and d=row 3, y=a +bxcalc+c*ccalc^2+dxdcalc^3
number xcalc=xvalue-getpixel(constantarray,i,4)
yspline=getpixel(constantarray,i,0)+getpixel(constantarray,i,1)*xcalc+getpixel(constantarray,i,2)*xcalc**2+getpixel(constantarray,i,3)*xcalc**3

return yspline
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

number integral_peaks, integral_fq2,n,c
number xsize, ysize,xscale,scale
spectrum.getsize(xsize,ysize)
xscale=spectrum.ImageGetDimensionScale(0)
scale=1/trunc(xsize/xsize)  //������������

//ɾ����ʱ����
TagGroup tg = spectrum.ImageGetTagGroup()
TagGroup tg1
if(tg.taggroupgettagastaggroup("ElectronDiffraction Tools:Background", tg1))
deletenote(spectrum, "ElectronDiffraction Tools:Background")

//���õ�ǰroi
number flagBG
getpersistentnumbernote("ElectronDiffraction Tools:PDF:Default Values:Auto BG", flagBG)

If(ControlDown())  //�����Զ�����
{
flagBG=abs(flagBG-1)
GetNumber("Auto background (1 or 0)?",flagBG,flagBG)
Setpersistentnumbernote("ElectronDiffraction Tools:PDF:Default Values:Auto BG", flagBG)
}

number x,y,l,r,intensity,value,minval
String mcplabel 
ROI currentROI 

theroi.roigetrange(l,r)
if(flagBG==1)  //�Զ�����
{
number minr,maxr
minr=r-3
maxr=r+3
minval=imgdisp{"I(Q)"}[0,minr,1,maxr].min(x,y)
x=minr+x

if((x>minr&&x<maxr))theroi.roiSetrange(x,x)
else theroi.roiSetrange(r,r)
}

if(flagBG==0)  //�ֶ�����
{
theroi.roiSetrange(r,r)
}

number roino= imgdisp.ImageDisplayCountROIS()
for (number i=0; i<roino; i++)
{
currentROI = imgdisp.ImageDisplayGetROI(i)
currentROI.roigetrange(l,r)

currentROI.roisetvolatile(0)
currentROI.roisetcolor(1,0,1)

intensity=spectrum.GetPixel(r,0) 
x=r/1000   //Ϊ��������
setnumbernote(spectrum,"ElectronDiffraction Tools:Background:"+x+":X",r*scale)
setnumbernote(spectrum,"ElectronDiffraction Tools:Background:"+x+":Intensity",intensity)
}

//��ȡ���棬׼��temp�ļ�
tg.taggroupgettagastaggroup("ElectronDiffraction Tools:Background", tg1)
number mcpno=tg1.taggroupcounttags()
image temp=integerimage("",2,1,mcpno,2)
for(number i=1; i<mcpno+1; i++)
{
mcplabel = tg1.TagGroupGetTaglabel( i-1 )
value=val(mcplabel)

getnumbernote(spectrum,"ElectronDiffraction Tools:Background:"+value+":X",x)
getnumbernote(spectrum,"ElectronDiffraction Tools:Background:"+value+":Intensity",Intensity)
setpixel(temp, i-1,0,x)
setpixel(temp, i-1,1,intensity)
}

// ����abcd
image arrayimg=calculatesplineconstants(temp)

//���㱳��
mcplabel = tg1.TagGroupGetTaglabel( 0 ) //��һ��roi
value=val(mcplabel)
getnumbernote(spectrum,"ElectronDiffraction Tools:Background:"+value+":X",x)

spectrum.getsize(xsize,ysize)
image SmallImg=RealImage("",4, xsize*scale,1)
for(number i=x; i<trunc(xsize*scale); i++)  //���״ӵ�һ��roi��ʼ��ע�����ԭ��
{
number yspline=fastcubicspline(arrayimg, i,1)
setpixel(SmallImg,i,0,yspline)
}

//����ͼ��
x=x/scale
splineimg=warp(SmallImg,icol*scale,irow*1)
splineimg[0,0,1,x]=spectrum[0,0,1,x]  //��һ�����׵���ǰ��ֵΪԭʼֵ
imgdisp{"Background"}=splineimg

//��ӷ�λͼ��
peaks=spectrum-splineimg

//��ȡ���������ڵĻ���ֵ
integral_peaks=peaks[0,x,1,xsize].sum()*xscale	
integral_fq2=fq2[0,x,1,xsize].sum()*xscale	

//����I(Q)ͼ��
n=integral_fq2/integral_peaks
Iq=n*peaks
imgdisp{"I(Q)"}=Iq  //�Ѿ���һ����

setnumbernote(spectrum,"ElectronDiffraction Tools:PDF:Parameters:N0",n) //��Iq-Fq�е���

//���㳣��c
number fittingchannels
getpersistentnumbernote("ElectronDiffraction Tools:PDF:Default Values:Fit to Top channel %",fittingchannels)
fittingchannels=1-(fittingchannels/100)

if(fittingchannels>0.99) fittingchannels=0.99
if(fittingchannels<0.01) fittingchannels=0.01	
number maxval=Iq[0, fittingchannels*xsize, 1, xsize].max(x,y)
c=fq2.GetPixel(fittingchannels*xsize+x,0)-Iq.GetPixel(fittingchannels*xsize+x,0)/2

Fq=(icol*xscale)*(Iq-fq2+c)/(f2q) 
imgdisp{"F(Q)"}=Fq

setnumbernote(spectrum,"ElectronDiffraction Tools:PDF:Parameters:N",1)
setnumbernote(spectrum,"ElectronDiffraction Tools:PDF:Parameters:C",c)

if(thisroiid==SpecialROIID)theroi.roisetlabel("BG\nN="+n+"\nc="+c)
else theroi.roisetlabel("N="+n+"\nc="+c)

number  autoContrast
getpersistentnumbernote("ElectronDiffraction Tools:PDF:Default Values:Auto Contrast", autoContrast)
if( autoContrast==1)
{

number min1,max1
Fq[0,0.1*xsize,1,xsize].minmax(min1,max1)
imgdisp.LinePlotImageDisplaySetDoAutoSurvey( 0, 0 ) 
imgdisp.LinePlotImageDisplaySetContrastLimits(1.1*min1,1.1*max1)  
}

else
{
//������
}

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
if(slicename=="Background"||slicename=="I(Q)") imgdisp.imagedisplaydeleteslicewithid(sliceid)
}

object sliceid=imgdisp.imagedisplaygetsliceidbyindex(0)
imgdisp.imagedisplaysetslicelabelbyid(sliceid, "I(Q)")

number min1,max1
imgdisp{"F(Q)"}.minmax(min1,max1)

imgdisp.lineplotimagedisplaysetdisplayedchannels(0,xsize) 
imgdisp.LinePlotImageDisplaySetContrastLimits(1.1*min1,1.1*max1)
imgdisp.LinePlotImageDisplaySetDoAutoSurvey(0,0)

number n,c
getnumbernote(spectrum,"ElectronDiffraction Tools:PDF:Parameters:N0",n) 
getnumbernote(spectrum,"ElectronDiffraction Tools:PDF:Parameters:C",c)
result("N="+n+", c="+c+"\n")
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
			theroi.roisetcolor(0,0,1)
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
if(slicename=="Background"||slicename=="I(Q)"||slicename=="F(Q)") imgdisp.imagedisplaydeleteslicewithid(sliceid)
}

image slice3=img*0
imgdisp.imagedisplayaddimage(slice3, "Background")  //ͼ��4�����Background
lineplotimagedisplaysetslicedrawingstyle(imgdisp,3,1)
lineplotimagedisplaysetslicecomponentcolor(imgdisp, 3, 0,0,0,1)

image slice4=img*0
imgdisp.imagedisplayaddimage(slice4, "I(Q)")  //ͼ��5�����I(Q)
imgdisp.LinePlotImageDisplaySetLegendShown(1)
lineplotimagedisplaysetslicedrawingstyle(imgdisp,4,1)
lineplotimagedisplaysetslicecomponentcolor(imgdisp, 4, 0,1,0,0)

image slice5=img*0
imgdisp.imagedisplayaddimage(slice5, "F(Q)")  //ͼ��6�����F(Q)
imgdisp.LinePlotImageDisplaySetLegendShown(1)
lineplotimagedisplaysetslicedrawingstyle(imgdisp,5,1)
lineplotimagedisplaysetslicecomponentcolor(imgdisp, 5, 0,0,0,1)

number t,l,b,r,minx,miny
img.getselection(t,l,b,r)
img.clearselection()

//��ʾ��
result("--------------------------------------------------------------------------\nROI changed: fit Background\nCtrl+ROI: to set auto background."+"--------------------------------------------------------------------------\n")

//----------------------------------------��ʼ�Զ�Ѱ�ұ���-------------------
//ɾ����ʱ����
TagGroup tg = img .ImageGetTagGroup()
TagGroup tg1
if(tg.taggroupgettagastaggroup("ElectronDiffraction Tools:Background", tg1)) tg1.TagGroupDeleteAllTags()

///�����ʼĩ����roi���Զ�ʶ��Сֵ
number minl=l-10
number maxl=l+10
img[0,minl,1,maxl].min(minx,miny)
minx=minl+minx

roi roi1=createroi()
if(minx>minl&&minx<maxl)ROI1.ROISetrange(minx,minx)
else ROI1.ROISetrange(l,l)
imgdisp.ImageDisplayAddROI( ROI1)
roi1.roisetvolatile(0)

number minr=r-20
number maxr=xsize-1
img[0,minr,1,maxr].min(minx,miny)
minx=minr+minx

roi1=createroi()
if(minx>minr&&minx<maxr)ROI1.ROISetrange(minx,minx)
else ROI1.ROISetrange(r,r)
imgdisp.ImageDisplayAddROI( ROI1)
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
