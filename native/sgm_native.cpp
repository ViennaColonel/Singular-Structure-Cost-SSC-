#include "mex.h"
#include <algorithm>
#include <cmath>
#include <limits>
#include <utility>
#include <vector>

void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]) {
    if (nrhs != 4 || nlhs > 1) {
        mexErrMsgIdAndTxt("SGM:Arguments",
            "Usage: disparity = sgm_disparity_mex(cost,P1,P2,minDisparity)");
    }
    const mxArray* cost = prhs[0];
    if ((!mxIsDouble(cost) && !mxIsSingle(cost)) || mxIsComplex(cost)) {
        mexErrMsgIdAndTxt("SGM:CostType", "Cost must be a real single or double array.");
    }
    const mwSize numberOfDimensions = mxGetNumberOfDimensions(cost);
    const mwSize* dimensions = mxGetDimensions(cost);
    if (numberOfDimensions < 3 || dimensions[2] < 2) {
        mexErrMsgIdAndTxt("SGM:CostSize", "Cost must be H-by-W-by-D with D >= 2.");
    }

    const mwSize height = dimensions[0];
    const mwSize width = dimensions[1];
    const mwSize disparities = dimensions[2];
    const mwSize pixels = height * width;
    const mwSize elements = pixels * disparities;
    const double P1 = mxGetScalar(prhs[1]);
    const double P2 = mxGetScalar(prhs[2]);
    const double minimumDisparity = mxGetScalar(prhs[3]);
    if (!(P1 > 0.0 && P2 > P1)) {
        mexErrMsgIdAndTxt("SGM:Penalties", "Penalties must satisfy P2 > P1 > 0.");
    }

    std::vector<double> directionCost(elements, 0.0);
    std::vector<double> summedCost(elements, 0.0);
    const double* doubleCost = mxIsDouble(cost)
        ? static_cast<const double*>(mxGetData(cost)) : nullptr;
    const float* singleCost = mxIsSingle(cost)
        ? static_cast<const float*>(mxGetData(cost)) : nullptr;
    const auto readCost = [doubleCost,singleCost](mwIndex index) {
        return doubleCost ? doubleCost[index] : static_cast<double>(singleCost[index]);
    };
    const int directions[8][2] = {
        { 1, 0}, { 1, 1}, { 0, 1}, {-1, 1},
        {-1, 0}, {-1,-1}, { 0,-1}, { 1,-1}
    };

    for (const auto& direction : directions) {
        const int dx = direction[0];
        const int dy = direction[1];
        std::vector<std::pair<int,int>> pathStarts;
        pathStarts.reserve(height+width);
        for (int y=0; y<static_cast<int>(height); ++y) {
            for (int x=0; x<static_cast<int>(width); ++x) {
                const int previousX=x-dx;
                const int previousY=y-dy;
                if (previousX<0 || previousX>=static_cast<int>(width) ||
                        previousY<0 || previousY>=static_cast<int>(height)) {
                    pathStarts.emplace_back(x,y);
                }
            }
        }

        for (int pathIndex=0; pathIndex<static_cast<int>(pathStarts.size()); ++pathIndex) {
            int x=pathStarts[pathIndex].first;
            int y=pathStarts[pathIndex].second;
            bool boundary=true;
            while (x>=0 && x<static_cast<int>(width) &&
                    y>=0 && y<static_cast<int>(height)) {
                const mwIndex pixel = static_cast<mwIndex>(y) +
                    static_cast<mwIndex>(x)*height;
                if (boundary) {
                    for (mwIndex d=0; d<disparities; ++d) {
                        const mwIndex index = pixel+d*pixels;
                        directionCost[index] = readCost(index);
                        summedCost[index] += directionCost[index];
                    }
                    boundary=false;
                } else {
                    const int previousX=x-dx;
                    const int previousY=y-dy;
                    const mwIndex previousPixel=static_cast<mwIndex>(previousY)+
                        static_cast<mwIndex>(previousX)*height;
                    double previousMinimum=std::numeric_limits<double>::infinity();
                    for (mwIndex d=0; d<disparities; ++d) {
                        previousMinimum=std::min(previousMinimum,
                            directionCost[previousPixel+d*pixels]);
                    }
                    for (mwIndex d=0; d<disparities; ++d) {
                        const double same=directionCost[previousPixel+d*pixels];
                        const double lower=d>0
                            ? directionCost[previousPixel+(d-1)*pixels]+P1
                            : std::numeric_limits<double>::infinity();
                        const double upper=d+1<disparities
                            ? directionCost[previousPixel+(d+1)*pixels]+P1
                            : std::numeric_limits<double>::infinity();
                        const double other=previousMinimum+P2;
                        const double transition=std::min(std::min(same,lower),
                            std::min(upper,other));
                        const mwIndex index=pixel+d*pixels;
                        directionCost[index]=readCost(index)+transition-previousMinimum;
                        summedCost[index]+=directionCost[index];
                    }
                }
                x+=dx;
                y+=dy;
            }
        }
    }

    plhs[0] = mxCreateDoubleMatrix(height,width,mxREAL);
    double* output = mxGetDoubles(plhs[0]);
    for (mwIndex pixel=0; pixel<pixels; ++pixel) {
        mwIndex best=0;
        double bestCost=summedCost[pixel];
        for (mwIndex d=1; d<disparities; ++d) {
            const double candidate=summedCost[pixel+d*pixels];
            if (candidate<bestCost) {
                bestCost=candidate;
                best=d;
            }
        }
        output[pixel]=minimumDisparity+static_cast<double>(best);
    }
}
